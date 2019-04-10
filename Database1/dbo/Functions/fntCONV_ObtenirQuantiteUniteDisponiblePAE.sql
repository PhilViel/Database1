/****************************************************************************************************
Copyrights (c) 2017 Gestion Universitas inc.

Code du service     : fntCONV_ObtenirQuantiteUniteDisponiblePAE
Nom du service		: 
But 				: Permet d'obtenir le nombre d'unités admissible à un PAE 
Description		: Cette fonction est appelée à chaque fois qu'il est nécesaire d'obtenir le nombre d'unités admissibles à un PAE
Facette			: CONV
Référence			: 

Paramètres d’entrée	:	Paramètre					Obligatoire	Description
					    --------------------------	-----------	-----------------------------------------------------------------
					    @idConvention				Non			ID de la convention pour laquelle on veut le statut, par défaut, pour tous

Exemple d'appel : 
        SELECT * FROM dbo.fntCONV_ObtenirQuantiteUniteDisponiblePAE(NULL)
        SELECT * FROM dbo.fntCONV_ObtenirQuantiteUniteDisponiblePAE(356490)
        
Historique des modifications:
        Date        Programmeur			    Description						Référence
        ----------  ------------------      ---------------------------  	------------
        2017-11-21  Pierre-Luc Simard       Création de la fonction		
        2017-12-12  Pierre-Luc Simard       Arrondi du taux d'avancement à 4 décimales
*********************************************************************************************************************/
CREATE FUNCTION [dbo].[fntCONV_ObtenirQuantiteUniteDisponiblePAE]
(
	@iConventionID	INT = NULL
)
RETURNS TABLE AS
RETURN (
WITH CTE_Unit AS (
    -- Liste des groupe d'unités
    SELECT 
        U.UnitID,
        U.ConventionID,
        U.ModalID,
        U.UnitQty,
        U.IntReimbDate,
        bArret_PaiementForce = CASE WHEN ISNULL(U.PmtEndConnectID, 0) <> 0 THEN 1 ELSE 0 END 
    FROM dbo.Un_Unit U
    JOIN Un_Convention C ON C.ConventionID = U.ConventionID
    JOIN dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(@iConventionID, NULL) CS ON CS.ConventionID = C.ConventionID
    WHERE 0=0 
        AND U.ConventionID = ISNULL(@iConventionID, U.ConventionID) 
        AND U.TerminatedDate IS NULL -- Non résilié   
        AND ISNULL(U.ActivationConnectID, 0) <> 0 -- Activé
        AND C.PlanID <> 4
        AND CS.ConventionStateID = 'REE' 
    ),
    CTE_ConvAvecDateRIN AS (
        -- Liste des RIN non-annulés
        SELECT DISTINCT 
            U.ConventionID
        FROM CTE_Unit U
        WHERE U.IntReimbDate IS NOT NULL 
    ),
    CTE_ConvAvecRIN AS (
        -- Liste des RIN non-annulés
        SELECT DISTINCT 
            U.ConventionID
        FROM Un_Oper O
        LEFT JOIN Un_OperCancelation OC ON OC.OperSourceID = O.OperID
        LEFT JOIN Un_OperCancelation OC2 ON OC2.OperID = O.OperID
        JOIN Un_Cotisation CT ON CT.OperID = O.OperID
        JOIN CTE_Unit U ON U.UnitID = CT.UnitID
        WHERE O.OperTypeID = 'RIN'
            AND OC.OperSourceID IS NULL -- Pas annulé
            AND OC2.OperID IS NULL -- Pas une annulation
        ),
    CTE_ConvAvecRIO AS (
        -- Liste des RIO non-annulés
        SELECT DISTINCT 
            R.iID_Convention_Source
        FROM tblOPER_OperationsRIO R 
        JOIN CTE_Unit U ON U.ConventionID = R.iID_Convention_Source
        WHERE R.iID_Convention_Source = ISNULL(@iConventionID, R.iID_Convention_Source)
            AND R.bRIO_Annulee = 0 
            AND R.bRIO_QuiAnnule = 0
    ),
    CTE_UnitSansRI AS (
        -- Liste des conventions sans RIN et sans RIO
        SELECT DISTINCT
            U.UnitID
        FROM CTE_Unit U
        LEFT JOIN CTE_ConvAvecDateRIN DRIN ON DRIN.ConventionID = U.ConventionID
        LEFT JOIN CTE_ConvAvecRIN RIN ON RIN.ConventionID = U.ConventionID
        LEFT JOIN CTE_ConvAvecRIO RIO ON RIO.iID_Convention_Source = U.ConventionID
        WHERE DRIN.ConventionID IS NULL
            AND RIN.ConventionID IS NULL 
            AND RIO.iID_Convention_Source IS NULL 
    ),
    CTE_Cotisation AS (
        -- Cotisation versées
        SELECT 
		    CT.UnitID,
            Cotisation = SUM(CT.Cotisation),
            Frais = SUM(CT.Fee)
	    FROM Un_Cotisation CT 
        JOIN Un_Oper O ON O.OperID = CT.OperID
        JOIN Un_Unit U ON U.UnitID = CT.UnitID AND U.ConventionID = ISNULL(@iConventionID, U.ConventionID) 
        --JOIN CTE_UnitSansRI U ON U.UnitID = CT.UnitID AND ISNULL(@iConventionID, 0) <> 0 -- On applique le filtre uniquement si une convention est passée en paramètre sinon c'est lent
        WHERE O.OperDate <= GETDATE()
	    GROUP BY CT.UnitID
    ),
    CTE_ConventionMontantSouscrit AS (
        -- Calcul du montant déposé et du montant souscrit
        SELECT 
            U.ConventionID,
            UnitQty = SUM(U.UnitQty),
            bRIN_Verse = MAX(CASE WHEN UR.UnitID IS NOT NULL THEN 0 ELSE 1 END),
            Depot = SUM(ISNULL(CT.Cotisation, 0) + ISNULL(CT.Frais, 0)),                        
            MontantSouscrit = SUM(CONVERT(MONEY,
                                    CASE
					                    WHEN U.bArret_PaiementForce = 0 THEN 
						                    (ROUND(U.UnitQty * M.PmtRate, 2) * M.PmtQty) 
					                    ELSE ISNULL(CT.Cotisation, 0) + ISNULL(CT.Frais, 0) 
				                    END))   
        FROM CTE_Unit U
        JOIN Un_Convention C ON C.ConventionID = U.ConventionID
        JOIN Un_Modal M ON M.ModalID = U.ModalID
        LEFT JOIN CTE_Cotisation CT ON CT.UnitID = U.UnitID
        LEFT JOIN CTE_UnitSansRI UR ON UR.UnitID = U.UnitID
        GROUP BY 
            U.ConventionID--, 
            --UR.UnitID
    ),
    CTE_ConvAvancement AS (
        -- Calcul du taux d'avancement
        SELECT 
            CM.ConventionID,
            CM.UnitQty,
            CM.bRIN_Verse,
            CM.Depot,
            CM.MontantSouscrit, 
            Taux_Avancement =   CASE  
                                    WHEN bRIN_Verse = 1 THEN 1 
                                    WHEN CM.MontantSouscrit = 0 THEN 0 
                                    ELSE 
                                        CASE WHEN CAST(CM.Depot AS DECIMAL(10, 4)) / CAST(CM.MontantSouscrit AS DECIMAL(10, 4)) > 1 THEN 1 
                                        ELSE CAST(CAST(CM.Depot AS DECIMAL(10, 4)) / CAST(CM.MontantSouscrit AS DECIMAL(10, 4)) AS DECIMAL(10, 4))
                                        END 
                                END    
        FROM CTE_ConventionMontantSouscrit CM
    )
    -- Calcul des unités disponibles pour un PAE
    SELECT 
        C.ConventionID,
        C.UnitQty,
        C.bRIN_Verse,
        C.Depot,
        C.MontantSouscrit,
        C.Taux_Avancement,
        mQuantite_UniteDemande = ISNULL(S.mQuantite_UniteDemande, 0), 
        Unites_Disponibles_PAE = CAST(
                                    CASE 
                                        WHEN (C.UnitQty * C.Taux_Avancement) - ISNULL(S.mQuantite_UniteDemande, 0) < 0 THEN 0
                                    ELSE 
                                        (C.UnitQty * C.Taux_Avancement) - ISNULL(S.mQuantite_UniteDemande, 0)
                                    END AS DECIMAL(10,3))    
    FROM CTE_ConvAvancement C
    LEFT JOIN (
        -- Calcul des unités déjà versés en PAE
        SELECT 
            S.ConventionID, 
            mQuantite_UniteDemande = SUM(ISNULL(S.mQuantite_UniteDemande, 0))
        FROM Un_Scholarship S
        WHERE S.ConventionID = ISNULL(@iConventionID, S.ConventionID)
            AND S.ScholarshipStatusID IN ('24Y','25Y','DEA','PAD','REN')
        GROUP BY S.ConventionID
        ) S ON S.ConventionID = C.ConventionID
)