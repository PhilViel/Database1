/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psCONV_ObtenirConventionAdmissibleAjoutCotisation
Nom du service		: Obtenir la listes des conventions admissibles à un ajout de cotisation
But 				: Obtenir la listes des conventions admissibles à un ajout de cotisation
Facette				: CONV
Référence			: Noyau-CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				@iIdSouscripteur			Identifiant du souscripteur
							
Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
													iIDConvention
													vcNoConvention
													fQteUnites
													vcRegime
													planId
													beneficiaireId
													vcBeneficiaire
		
Exemple utilisation:																					
	
		EXEC psCONV_ObtenirConventionAdmissibleAjoutCotisation 190030
        EXEC psCONV_ObtenirConventionAdmissibleAjoutCotisation 756863 -- Exemple de BEC
	
TODO:
	
Historique des modifications:
	Date		Programmeur		    Description									Référence
	----------  --------------------    -----------------------------------------	------------
    2016-10-28	Pierre-Luc Simard	    Création du service		
    2016-11-04  Pierre-Luc Simard       Exclure les conventions n'ayant que du BEC
    2016-11-08  Pierre-Luc Simard       Exclure temporairement les conventions qui n'ont pas de compte bancaire et les convention "T-"
    2016-11-14  Pierre-Luc Simard       Remettre les conventions sans compte bancaire et les convention "T-"
	2016-11-16	Maxime Martel			Retourner aussi les conventions collectives qui ont un beneficaire agé de 17 ans
	2017-10-25	Philippe Dubé-Tremblay	Retourner l'état de maximisation de la convention
	2017-10-25	Guehel Bouanga			Inclure les conventions n'ayant que du BEC		( MC-315 ) 
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_ObtenirConventionAdmissibleAjoutCotisation]
	@iIdSouscripteur INT
AS
BEGIN
	SET NOCOUNT ON;

    SELECT
	   	iID_Convention = C.ConventionID,
		vcNumero_Convention = C.ConventionNo,
        iID_Plan = C.PlanID,
		iID_Beneficiaire = C.BeneficiaryID,
        vcNom_Benefiaire = HB.LastName,
		vcPrenom_Beneficiaire = HB.FirstName,
        dDate_NaissanceBeneficiaire = HB.BirthDate,
        BT.BankTypeName,
        BT.BankTypeCode,
        B.BankTransit,
        CA.TransitNo,
        CA.AccountName,
        mSolde_Epargne = ISNULL(CT.mSolde_Epargne, 0),
        mSolde_Frais = CASE WHEN P.PlanTypeID = 'IND' THEN 0 ELSE ISNULL(CT.mSolde_Frais, 0) END,
		tiMaximisationREEE = C.tiMaximisationREEE	
	FROM dbo.Un_Convention C
    JOIN Un_Plan P ON P.PlanID = C.PlanID
    JOIN dbo.Mo_Human HB ON C.BeneficiaryID = HB.HumanID
    LEFT JOIN Un_ConventionAccount CA ON CA.ConventionID = C.ConventionID
    LEFT JOIN Mo_Bank B ON B.BankID = CA.BankID
    LEFT JOIN Mo_BankType BT ON BT.BankTypeID = B.BankTypeID
    JOIN fntCONV_ObtenirStatutConventionEnDate_PourTous(NULL, NULL) CS ON CS.ConventionID = C.ConventionID
    LEFT JOIN (
        SELECT 
            U.ConventionID,
            mSolde_Epargne = SUM(CT.Cotisation),
            mSolde_Frais = SUM(CT.Fee)
        FROM Un_Unit U 
        JOIN Un_Cotisation CT ON CT.UnitID = U.UnitID
        JOIN Un_Oper O ON O.OperID = CT.OperID
        WHERE O.OperDate <= GETDATE()
        GROUP BY U.ConventionID
        ) CT ON CT.ConventionID = C.ConventionID
    --LEFT JOIN ( -- Liste des convention n'ayant que du BEC
    --    SELECT DISTINCT
    --        BEC.ConventionID
    --    FROM ( -- Liste des conventions I avec du BEC
    --        SELECT DISTINCT
    --            C.ConventionID
    --        FROM Un_Convention C
    --        JOIN Un_Unit U ON C.ConventionID = U.ConventionID
    --        JOIN Un_Cotisation CT ON U.UnitID = CT.UnitID
    --        JOIN Un_Oper O ON CT.OperID = O.OperID
    --        LEFT JOIN Un_OperCancelation OC1 ON O.OperID = OC1.OperSourceID
    --        LEFT JOIN Un_OperCancelation OC2 ON O.OperID = OC2.OperID
    --        WHERE C.ConventionNo LIKE 'I-%'
    --            AND O.OperTypeID = 'BEC'
    --            AND OC1.OperSourceID IS NULL
    --            AND OC2.OperID IS NULL
    --            AND U.RepID = 149876 -- SIÈGE SOCIAL
    --        ) BEC 
    --    --LEFT JOIN (  -- Liste des conventions I des cotisations autre que du BEC pour les exclure
    --    --    SELECT DISTINCT
    --    --        C.ConventionID
    --    --    FROM Un_Convention C
    --    --    JOIN Un_Unit U ON C.ConventionID = U.ConventionID
    --    --    JOIN Un_Cotisation CT ON U.UnitID = CT.UnitID
    --    --    JOIN Un_Oper O ON CT.OperID = O.OperID
    --    --    LEFT JOIN Un_OperCancelation OC1 ON O.OperID = OC1.OperSourceID
    --    --    LEFT JOIN Un_OperCancelation OC2 ON O.OperID = OC2.OperID
    --    --    WHERE C.ConventionNo LIKE 'I-%'
    --    --        AND O.OperTypeID <> 'BEC'
    --    --        AND (CT.Cotisation <> 0
    --    --                OR CT.Fee <> 0
    --    --            )
    --    --        AND OC1.OperSourceID IS NULL
    --    --        AND OC2.OperID IS NULL
    --    --        AND U.RepID = 149876 -- SIÈGE SOCIAL
    --    --    ) NOT_BEC ON NOT_BEC.ConventionID = BEC.ConventionID
    --    --WHERE NOT_BEC.ConventionID IS NULL
    --    ) BEC ON BEC.ConventionID = C.ConventionID
	WHERE C.SubscriberID = @iIdSouscripteur
	    AND CS.ConventionStateID <> 'FRM'
        --AND BEC.ConventionID IS NULL
        AND dbo.fn_Mo_Age(HB.BirthDate, GETDATE()) <= 17
    ORDER BY 
        HB.LastName,
		HB.FirstName,
        C.ConventionNo        

END