/****************************************************************************************************
Copyrights (c) 2018 Gestion Universitas inc.

Code du service     : fntCONV_ObtenirNombreUniteIndividuelSelonFraisEnDate
Nom du service		: fntCONV_ObtenirNombreUniteIndividuelSelonFraisEnDate
But 				: Permet d'obtenir le nombre d'unité selon les frais cotisé de toutes les conventions individuel en fonction d'une date
Description		    : Cette fonction est appelée à chaque fois qu'il est nécesaire d'obtenir le nombre d'unité d'une convention individuel selon les frais cotisé
Facette			    : CONV
Référence			: 

Paramètres d’entrée	:	Paramètre				Obligatoire	Description
					--------------------------	-----------	-----------------------------------------------------------------
					@dtDate						Non			Date à laquelle on veut récupérer le nombre d'unité, par défaut, ce sont les actuels
					@idConvention				Non			ID de la convention pour laquelle on veut le nombre d'unité, par défaut, pour tous

Exemple d'appel : 
        SELECT * FROM dbo.fntCONV_ObtenirNombreUniteIndividuelSelonFraisEnDate(NULL, NULL)
        SELECT * FROM dbo.fntCONV_ObtenirNombreUniteIndividuelSelonFraisEnDate(NULL, 466933)
        SELECT * FROM dbo.fntCONV_ObtenirNombreUniteIndividuelSelonFraisEnDate('2017-05-15', NULL)
        SELECT * FROM dbo.fntCONV_ObtenirNombreUniteIndividuelSelonFraisEnDate('2017-05-14', 370289)

NE PAS OUBLIER DE CHANGER LA FONCTION DANS LE C# (GUI.Domain.PortailClient.Entities.Convention -> ObtenirFraisConventionIndividuelle)

Historique des modifications:
        Date        Programmeur			Description						
        ----------  ------------------  ---------------------------  	
        2015-09-30  Maxime Martel       JIRA : MC-381 Créer la fonction sql de calcul du nombre d'unités
        2018-05-10  Pierre-Luc Simard   Ne plus tenir compte des TFR puisque le système de commissions gère déjà les exceptions
*********************************************************************************************************************/
CREATE FUNCTION [dbo].[fntCONV_ObtenirNombreUniteIndividuelSelonFraisEnDate]
(
	@dtDateStatut DATETIME = NULL,
	@idConvention INT = NULL
)
RETURNS TABLE AS
RETURN (
	WITH CTE_Unit AS (
		SELECT 
			C.ConventionID,
			C.ConventionNo,
			U.UnitID,
			U.UnitQty
		FROM Un_Convention C
		JOIN Un_Unit U ON U.ConventionID = C.ConventionID
        WHERE C.ConventionID = ISNULL(@idConvention, C.ConventionID)
            AND C.PlanID = 4 -- Individuel
    ), CTE_Cotisation AS (
        SELECT 
            U.ConventionID,
		    U.ConventionNo,
            U.UnitID,
            mSolde_Frais_Sans_RIN = SUM(CT.Fee)                                     
        FROM CTE_Unit U 
        JOIN Un_Cotisation CT ON CT.UnitID = U.UnitID
		JOIN Un_Oper O ON O.OperID = CT.OperID
		/*LEFT JOIN (
			SELECT 
				CT.CotisationID
			FROM Un_Oper O
			JOIN Un_Cotisation CT ON CT.OperID = O.OperID
			LEFT JOIN Un_OtherAccountOper OAO ON OAO.OperID = O.OperID
			LEFT JOIN Un_IntReimbOper IRO ON IRO.OperID = OAO.OperID
			LEFT JOIN Un_UnitReductionCotisation URC ON URC.CotisationID = CT.CotisationID
			WHERE O.OperTypeID = 'TFR' 
				AND CT.Fee < 0 
				AND IRO.OperID IS NULL 
				AND URC.CotisationID IS NULL
				AND o.OperID NOT in (
					SELECT 
						OperID
					FROM Un_OperCancelation
					UNION 
					SELECT 
						OperSourceID
					FROM Un_OperCancelation
				)
		) TFRSansRIN ON TFRSansRIN.CotisationID = CT.CotisationID*/
		LEFT JOIN Un_OtherAccountOper OAO ON OAO.OperID = O.OperID
		LEFT JOIN Un_IntReimbOper IRO ON IRO.OperID = OAO.OperID
		LEFT JOIN tblOPER_OperationsRIO R ON R.iID_Oper_RIO = O.OperID AND R.iID_Unite_Source = U.UnitID AND R.bRIO_Annulee = 0 AND R.bRIO_QuiAnnule = 0
        WHERE O.OperDate <= ISNULL(@dtDateStatut, GETDATE())
            AND O.OperTypeID NOT IN ('RIN', 'TRI') -- Exclure les RIN
			AND R.iID_Operation_RIO IS NULL -- Exclure les RIM, RIO et TRI sortant
			AND IRO.OperID IS NULL -- Exclure les frais éliminés suite à un RIN
			--AND TFRSansRIN.CotisationID IS NULL -- Exclure TFR non lié à un RIN
			--AND NOT (ISNULL(CT.Fee, 0) > 0 AND O.OperTypeID = 'TFR') -- Exclure les TFR positifs
        GROUP BY 
            U.ConventionID,
		    U.ConventionNo,
            U.UnitID
	)
	SELECT 
		U.ConventionID,
		U.ConventionNo,
		U.UnitID,
		UnitQty =   CAST(ROUND(CASE WHEN ISNULL(F.mSolde_Frais_Sans_RIN, 0) > 200 THEN 1 
					ELSE 
                        CASE WHEN ISNULL(F.mSolde_Frais_Sans_RIN, 0) < 0 THEN 0 
					    ELSE ISNULL(F.mSolde_Frais_Sans_RIN, 0) / 200 
                        END 
				    END,3) AS DECIMAL(5,3))
	FROM CTE_Unit U
	LEFT JOIN CTE_Cotisation F ON F.UnitID = U.UnitID
    )