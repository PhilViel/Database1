/*  *************************************************************
    *     _____                                _           _    *
    *    |  __ \                              | |         | |   *
    *    | |  | | ___ _ __  _ __ ___  ___ __ _| |_ ___  __| |   *
    *    | |  | |/ _ \ '_ \| '__/ _ \/ __/ _` | __/ _ \/ _` |   *
    *    | |__| |  __/ |_) | | |  __/ (_| (_| | ||  __/ (_| |   *
    *    |_____/ \___| .__/|_|  \___|\___\__,_|\__\___|\__,_|   *
    *                | |                                        *
    *                |_|                                        *
    ******************** D E P R E C A T E D ********************   */

/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service		: psIQEE_RapportBourseSansIQEE
Nom du service		: Rapport TEMPORAIRE
But 				: 
Facette				: IQÉÉ

Paramètres d’entrée	:	

Exemple d’appel		:	EXECUTE [dbo].[psIQEE_RapportBourseSansIQEE] '2010-03-17','2010-03-30'

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2010-07-28		Donald Huppé						Création du service							
		2010-08-17		Éric Deshaies						Enlever condition qu'il doit y avoir une
															opération IQE pour laisser passer les conventions T
        2017-09-27      Pierre-Luc Simard                   Deprecated - Cette procédure n'est plus utilisée

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psIQEE_RapportBourseSansIQEE] 
(
	@dtDateFrom datetime,
	@dtDateTo datetime
)
AS
BEGIN
    
    SELECT 1/0
    /*
	SELECT C.ConventionNo,S.ScholarshipNo,O.OperDate,							
		   CASE WHEN I.bPAE_Destine_Beneficiaire = 0 THEN 'X' ELSE '' END AS bPAE_Destine_Beneficiaire,						
		   CASE WHEN I.bBeneficiare_Quebec = 0 THEN 'X' ELSE '' END AS bBeneficiare_Quebec,						
		   CASE WHEN I.bConvention_Rejetee = 1 THEN 'X' ELSE '' END AS bConvention_Rejetee,						
		   CASE WHEN I.bConvention_Fermee = 1 THEN 'X' ELSE '' END AS bConvention_Fermee,						
		   CASE WHEN I.bRempl_Benef_Non_Reconnu = 1 THEN 'X' ELSE '' END AS bRempl_Benef_Non_Reconnu,						
		   CASE WHEN I.bTransfert_Non_Autorise = 1 THEN 'X' ELSE '' END AS bTransfert_Non_Autorise,						
		   CASE WHEN I.bRetrait_Premature = 1 THEN 'X' ELSE '' END AS bRetrait_Premature,						
		   CASE WHEN I.mMontant_PAE < 0 OR						
				   I.mJVM < 0 OR				
				   I.fPourcentage_PAE < 0 OR				
				   I.fPourcentage_PAE > 1 THEN 'X' ELSE '' END AS PAE_Pourc_Pas_Bon,				
		   CASE WHEN I.mSolde_Credit_Base < 0 OR						
				   I.mSolde_Majoration < 0 OR				
				   I.mSolde_Interets_RQ < 0 OR				
				   I.mSolde_Interets_IQI < 0 OR				
				   I.mSolde_Interets_ICQ < 0 OR				
				   I.mSolde_Interets_IMQ < 0 OR				
				   I.mSolde_Interets_IIQ < 0 OR				
				   I.mSolde_Interets_III < 0 THEN 'X' ELSE '' END AS CompteNegatif,				
		   I.mMontant_PAE,						
		   I.mJVM,						
		   I.fPourcentage_PAE,						
		   I.mSolde_Credit_Base,						
		   I.mSolde_Majoration,						
		   I.mSolde_Interets_RQ,						
		   I.mSolde_Interets_IQI,						
		   I.mSolde_Interets_ICQ,						
		   I.mSolde_Interets_IMQ,						
		   I.mSolde_Interets_IIQ,						
		   I.mSolde_Interets_III						
	FROM tblTEMP_InformationsIQEEPourPAE I							
		 JOIN CHQ_Operation CO ON CO.iOperationID = I.iID_Operation_Cheque						
							  AND CO.bStatus = 0	
		 LEFT JOIN Un_OperCancelation OC ON OC.OperSourceID = I.iID_Operation						
		 LEFT JOIN dbo.Un_Convention C ON C.ConventionID = I.iID_Convention						
		 LEFT JOIN Un_Oper O ON O.OperID = I.iID_Operation						
		 LEFT JOIN Un_ScholarshipPmt SP ON SP.OperID = O.OperID						
		 LEFT JOIN Un_Scholarship S ON S.ScholarshipID = SP.ScholarshipID						
	WHERE 
		O.OperDate between @dtDateFrom and @dtDateTo
	  AND OC.OperSourceID IS NULL							
	  AND (I.bPAE_Destine_Beneficiaire = 0							
	   OR I.bBeneficiare_Quebec = 0							
	   OR I.bConvention_Rejetee = 1							
	   OR I.bConvention_Fermee = 1							
	   OR I.bRempl_Benef_Non_Reconnu = 1							
	   OR I.bTransfert_Non_Autorise = 1							
	   OR I.bRetrait_Premature = 1							
	   OR I.mMontant_PAE < 0 OR							
		   I.mJVM < 0 OR						
		   I.fPourcentage_PAE < 0 OR						
		   I.fPourcentage_PAE > 1 OR						
		   I.mSolde_Credit_Base < 0 OR						
		   I.mSolde_Majoration < 0 OR						
		   I.mSolde_Interets_RQ < 0 OR						
		   I.mSolde_Interets_IQI < 0 OR						
		   I.mSolde_Interets_ICQ < 0 OR						
		   I.mSolde_Interets_IMQ < 0 OR						
		   I.mSolde_Interets_IIQ < 0 OR						
		   I.mSolde_Interets_III < 0)						
	  AND EXISTS(SELECT *							
				 FROM Un_ConventionOper CO2					
				 WHERE CO2.ConventionID = I.iID_Convention					
				   AND CO2.ConventionOperTypeID IN ('CBQ','MMQ','MIM'))				
	ORDER BY C.ConventionNo,S.ScholarshipNo,O.OperDate							
    */
End