/***********************************************************************************************************************
Copyrights (c) 2014 Gestion Universitas inc
Code du service		:	psIQEE_RapportIQEE_A_Recevoir_Detaille
But 				:	Rapport mensuel détaillé de l'IQEE à recevoir et à payer
Valeurs de retour   :	Dataset de données
Facette				:   IQÉÉ

Paramètres d’entrée	:	Aucun

Exemple d’appel		:	EXECUTE [dbo].[psIQEE_RapportIQEE_A_Recevoir_Detaille] '1368417'

Paramètres de sortie:	Aucun

Historique des modifications:
    Date		 Programmeur			Description								
    ----------  --------------------    -----------------------------------------
    2014-09-02	Stéphane Barbeau    	Création du service							
    2015-01-08	Stéphane Barbeau		Nouvelle version complète des requêtes
    2015-03-31	Stéphane Barbeau		Ajout de dtDate_Fin_ARecevoir dans le Dataset afin d'ajouter la date dans l'entête du rapport.
    2016-03-07	Steeve Picard			Ajout du paramètre optionel @ConventionNo pour avoir seulement celui-là
    2016-05-01  Steeve Picard           Optimisation et ajout du paramètre optionel «@BeneficiaryID»
    2018-01-23  Steeve Picard           Élimination des champs «Version & Statut»
    2018-11-08  Pierre-Luc Simard       Utilisation des regroupements de régimes
***********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psIQEE_RapportIQEE_A_Recevoir_Detaille] (
    @ConventionNo varchar(15) = NULL, 
    @BeneficiaryID INT = NULL
) AS 
BEGIN

		-- IQEE A recevoir des demandes de subventions (T02)
		SELECT	
				'T' + T.cCode_Type_Enregistrement as 'Type Enregistrement',
                    IsNull(T.SousTypeDescription, T.TypeDescription) as 'Sous-Type',
				
				--CASE R.tiVersion WHEN 0 THEN 'ORIGINALE'
				--                 WHEN 2 THEN 'REPRISE'
				--	            Else 'à corriger'
				--END As 'Version',
				--R.iID_Fichier_IQEE as 'ID Fichier IQEE',
				R.siAnnee_Fiscale as 'Année fiscale',
				
				--CASE R.cStatut WHEN 'A' THEN 'En attente'
				--	          WHEN 'E' THEN 'En erreur traitable' 
				--	          Else 'Inconnu'
				--END as 'Statut',  
				
				R.iID_Evenement as 'ID Evénement',
				R.dtEvenement as 'Date événement',
				R.iID_Convention as 'ID de Convention',
				R.vcNo_Convention as 'Numéro de convention',
				
				RR.vcDescription as 'Plan',
				
				R.siAnnee_Cohorte as 'Année cohorte',
				R.iID_Beneficiaire as 'ID Bénéficiaire',
				R.mMontant_Subventionnable as 'Total des cotisations subventionnables' , --[dbo].[fn_Mo_MoneyToStr](R.mTotal_Cotisations_Subventionnables,'FRA',1) as 'Total des cotisations subventionnables' ,
				R.mMontant_Admissible as 'Plafond des cotisations admissibles CBQ',
				R.mMontant_Majorable as 'Plafond desd cotisations majorables MMQ',
				R.fPourcentMajoration as '% MMQ reçu' ,
				R.mCreditBase_Estime as 'CBQ à recevoir', --[dbo].[fn_Mo_MoneyToStr](R.mCBQ_Estime,'FRA',1) as 'CBQ',
				0 as 'CBQ à payer',
				R.mMajoration_Estime as 'MMQ à recevoir', --[dbo].[fn_Mo_MoneyToStr](R.mMMQ_Estime,'FRA',1) as 'MMQ',
				0 as 'MMQ à Payer',
				R.mTotal_Estime as 'Total IQEE', --[dbo].[fn_Mo_MoneyToStr](R.mTotalEstimation,'FRA',1)  as 'Total IQEE' ,
				CAST (R.dtFin_ARecevoir as date) as 'Date Fin Estimation'
				
			FROM tblIQEE_Estimer_ARecevoir R
			JOIN dbo.Un_Convention C ON C.ConventionID = R.iID_Convention
               JOIN dbo.Un_Plan P ON P.PlanID = R.iID_Plan
               JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
               JOIN dbo.vwIQEE_Enregistrement_TypeEtSousType T ON T.tiID_Type_Enregistrement = R.tiID_TypeEnregistrement
                                                              AND IsNull(T.iID_Sous_Type, 0) = IsNull(R.iID_SousType, 0)

			Where R.vcNo_Convention = IsNull(@ConventionNo, R.vcNo_Convention)
                 And R.iID_Beneficiaire = IsNull(@BeneficiaryID, R.iID_Beneficiaire)

		UNION
		
		--IQEE à payer par les impôts spéciaux (T06)
		SELECT
				'T' + T.cCode_Type_Enregistrement as 'Type Enregistrement',
                    IsNull(T.SousTypeDescription, T.TypeDescription) as 'Sous-Type',
				
				--CASE R.tiVersion WHEN 0 THEN 'ORIGINALE'
				--                 WHEN 2 THEN 'REPRISE'
				--	            Else 'à corriger'
				--END As 'Version',
				--R.iID_Fichier_IQEE as 'ID Fichier IQEE',
				R.siAnnee_Fiscale as 'Année fiscale',
				
				--CASE R.cStatut WHEN 'A' THEN 'En attente'
				--	          WHEN 'E' THEN 'En erreur traitable' 
				--	          Else 'Inconnu'
				--END as 'Statut',  
				
				R.iID_Evenement as 'ID Evénement',
				R.dtEvenement as 'Date événement',
				
				R.iID_Convention as 'ID de Convention',
				
				R.vcNo_Convention as 'Numéro de convention',
				
				RR.vcDescription as 'Plan',

				R.siAnnee_Cohorte as 'Année cohorte',
				R.iID_Beneficiaire as 'ID Bénéficiaire',
				0 as 'Total des cotisations subventionnables' , --[dbo].[fn_Mo_MoneyToStr](R.mTotal_Cotisations_Subventionnables,'FRA',1) as 'Total des cotisations subventionnables' ,
				0 as 'Plafond des cotisations admissibles CBQ',
				0 as 'Plafond desd cotisations majorables MMQ',
				0 as '% MMQ reçu' ,
				0 as 'CBQ à recevoir',
				R.mCreditBase_Estime as 'CBQ à payer', --[dbo].[fn_Mo_MoneyToStr](R.mCBQ_Estime,'FRA',1) as 'CBQ',
				0 as 'MMQ à recevoir',
				R.mMajoration_Estime as 'MMQ à payer', --[dbo].[fn_Mo_MoneyToStr](R.mMMQ_Estime,'FRA',1) as 'MMQ',
				R.mTotal_Estime as 'Total IQEE', --[dbo].[fn_Mo_MoneyToStr](R.mTotalEstimation,'FRA',1)  as 'Total IQEE' ,
				CAST (R.dtFin_APayer as date) as 'Date Fin Estimation'
				
			FROM tblIQEE_Estimer_APayer R
               JOIN dbo.Un_Plan P ON P.PlanID = R.iID_Plan
               JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
               JOIN dbo.vwIQEE_Enregistrement_TypeEtSousType T ON T.tiID_Type_Enregistrement = R.tiID_TypeEnregistrement
                                                              AND IsNull(T.iID_Sous_Type, 0) = IsNull(R.iID_SousType, 0)
			Where R.vcNo_Convention = IsNull(@ConventionNo, R.vcNo_Convention)
                 And R.iID_Beneficiaire = IsNull(@BeneficiaryID, R.iID_Beneficiaire)

		Order BY siAnnee_Fiscale, vcNo_Convention  
	
END