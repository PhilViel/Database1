/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc
Nom                 : IU_UN_ProfilSubscriber
Description         : Sauvegarde d'ajouts/modifications du profil du souscripteurs
Valeurs de retours  : >0  :	Tout à fonctionné
                      <=0 :	Erreur SQL

Note :				2008-09-18	Radu Trandafir			Creation
					2008-11-10  Patrick Robitaille		Modification pour avoir le profil souscripteur dans le log du souscripteur
					2009-12-18	Jean-François Gauthier	Ajout des champs liés au profil du souscripteur
					2010-01-05	Jean-Françôis Gauthier	Modification des liés au profil du souscripteur
					2011-04-08	Corentin Menthonnex		2011-12 : ajout des champs suivants aux informations souscripteur
																	- vcJustifObjectifsInvestissement
					2011-10-31	Christian Chénard		Ajout des champs iID_Estimation_Cout_Etudes et iID_Estimation_Valeur_Nette_Menage
					2012-09-14	Donald Huppé			Ajout @iToleranceRisqueID
					2014-09-12	Pierre-Luc Simard		Gérer l'historique avec le champ DateProfilInvestisseur et ne plus gérer le log, puisque remplacé par l'historique
					2015-06-30  Steve Picard			Insert seulement si c'est le 1er & update pour les suivants, le trigger va historiser
					2015-10-20	Steve Picard			Correction pour l'erreur de Duplicate Key pour l'index «IX_ProfileSouscripteur_IID_Souscripteur_Date»
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_ProfilSubscriber] (
	@ConnectID INTEGER,
	@SubscriberID INTEGER,                     
	@ConnaissancePlacementsID INTEGER,
	@RevenuFamilialID INTEGER,
	@DepassementBaremeID BIT,
	@IdentiteSouscripteurID INTEGER,
	@ObjectifInvestissementLigne1ID INTEGER,
	@ObjectifInvestissementLigne2ID INTEGER,
	@ObjectifInvestissementLigne3ID INTEGER,
	@NoPersonnesACharge TINYINT,
	@vcIdentiteDescription VARCHAR(75),
	@vcDepassementJustification VARCHAR(75),
	@iIDNiveauEtudeMere	INT,				-- 2010-01-05 : JFG : Modification pour les champs suivants
	@iIDNiveauEtudePere INT,
	@iIDNiveauEtudeTuteur INT,
	@iIDImportanceEtude INT,
	@iIDEpargneEtudeEnCours INT,
	@iIDContributionFinanciereParent INT,
	@vcJustifObjectifsInvestissement	VARCHAR(150),	-- 2011-04-08 : + 2011-12 + CM
	@iID_Estimation_Cout_Etudes INT,
	@iID_Estimation_Valeur_Nette_Menage INT,
	@iToleranceRisqueID INTEGER) 
AS
BEGIN
	-----------------
	BEGIN TRANSACTION
	-----------------

	IF @SubscriberID <> 0
	BEGIN
		DECLARE @ProfilSubscriberID INT

		--	2015-10-20
		SELECT @ProfilSubscriberID = Max(iID_Profil_Souscripteur)
		  FROM dbo.tblCONV_ProfilSouscripteur
		 WHERE iID_Souscripteur = @SubscriberID

		---- Si le profil du souscripteur n'existe pas en date d'aujourd'hui, un nouveau profil est créé.
		IF IsNull(@ProfilSubscriberID, 0) = 0	-- 2015-10-20
		--IF NOT EXISTS(
		--		SELECT TOP 1 iID_Profil_Souscripteur
		--		FROM tblCONV_ProfilSouscripteur
		--		WHERE iID_Souscripteur = @SubscriberID
		--			--AND DateProfilInvestisseur = CONVERT(DATE, GETDATE())
		--	)
		BEGIN
			INSERT tblCONV_ProfilSouscripteur (
				iID_Souscripteur,
				iID_Connaissance_Placements,
				iID_Revenu_Familial,
				iID_Depassement_Bareme,
				iID_Identite_Souscripteur,
				iID_ObjectifInvestissementLigne1,
				iID_ObjectifInvestissementLigne2,
				iID_ObjectifInvestissementLigne3,
				tiNB_Personnes_A_Charge, 
				vcIdentiteVerifieeDescription,
				vcDepassementBaremeJustification,
				iIDNiveauEtudeMere					,				-- 2010-01-05 : JFG : Modification pour les champs suivants
				iIDNiveauEtudePere					,
				iIDNiveauEtudeTuteur				,
				iIDImportanceEtude					,
				iIDEpargneEtudeEnCours				,
				iIDContributionFinanciereParent		,
				vcJustifObjectifsInvestissement		,				-- 2011-04-08 : + 2011-12 + CM
				iID_Estimation_Cout_Etudes			,
				iID_Estimation_Valeur_Nette_Menage	,	
				iID_Tolerance_Risque)
			VALUES (
				@SubscriberID,
				@ConnaissancePlacementsID,
				@RevenuFamilialID,
				@DepassementBaremeID,
				@IdentiteSouscripteurID,
				@ObjectifInvestissementLigne1ID,
				@ObjectifInvestissementLigne2ID,
				@ObjectifInvestissementLigne3ID,
				@NoPersonnesACharge,
				@vcIdentiteDescription,
				@vcDepassementJustification,
				@iIDNiveauEtudeMere					,				-- 2010-01-05 : JFG : Modification pour les champs suivants
				@iIDNiveauEtudePere					,
				@iIDNiveauEtudeTuteur				,
				@iIDImportanceEtude					,
				@iIDEpargneEtudeEnCours				,
				@iIDContributionFinanciereParent	,
				@vcJustifObjectifsInvestissement	,				-- 2011-04-08 : + 2011-12 + CM
				@iID_Estimation_Cout_Etudes			,
				@iID_Estimation_Valeur_Nette_Menage	,
				@iToleranceRisqueID)
			
			IF @@ERROR <> 0
				SET @SubscriberID = 0

		END
		ELSE
		BEGIN
			-- Si le un profil existe déjà pour ce souscripteur en date d'aujourd'hui, on met à jour les informations
			UPDATE tblCONV_ProfilSouscripteur 
			SET 
				iID_Connaissance_Placements		= @ConnaissancePlacementsID,
				iID_Revenu_Familial					= @RevenuFamilialID,
				iID_Depassement_Bareme			= @DepassementBaremeID,
				iID_Identite_Souscripteur			= @IdentiteSouscripteurID,
				iID_ObjectifInvestissementLigne1	= @ObjectifInvestissementLigne1ID,
				iID_ObjectifInvestissementLigne2	= @ObjectifInvestissementLigne2ID,
				iID_ObjectifInvestissementLigne3	= @ObjectifInvestissementLigne3ID,
				tiNB_Personnes_A_Charge			= @NoPersonnesACharge,
				vcIdentiteVerifieeDescription		= @vcIdentiteDescription,
				vcDepassementBaremeJustification	= @vcDepassementJustification,
				iIDNiveauEtudeMere					= @iIDNiveauEtudeMere,					-- 2010-01-05 : JFG : Modification des champs
				iIDNiveauEtudePere						= @iIDNiveauEtudePere,		
				iIDNiveauEtudeTuteur					= @iIDNiveauEtudeTuteur,
				iIDImportanceEtude					= @iIDImportanceEtude,
				iIDEpargneEtudeEnCours				= @iIDEpargneEtudeEnCours,
				iIDContributionFinanciereParent	= @iIDContributionFinanciereParent,
				vcJustifObjectifsInvestissement	= @vcJustifObjectifsInvestissement,		-- 2011-04-08 : + 2011-12 + CM
				iID_Estimation_Cout_Etudes			= @iID_Estimation_Cout_Etudes,
				iID_Estimation_Valeur_Nette_Menage	= @iID_Estimation_Valeur_Nette_Menage,
				iID_Tolerance_Risque					= @iToleranceRisqueID
			WHERE iID_Profil_Souscripteur = @ProfilSubscriberID --	2015-10-20
				--iID_Souscripteur = @SubscriberID
				--AND DateProfilInvestisseur = CONVERT(DATE, GETDATE())

			IF @@ERROR <> 0
				SET @SubscriberID = 0
		END
	END

	IF @@ERROR = 0
		COMMIT TRANSACTION
	ELSE
	BEGIN
		ROLLBACK TRANSACTION
		SET @SubscriberID = 0
	END

	RETURN(@SubscriberID)
END
