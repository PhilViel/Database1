/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psGENE_RetournerMessageAccueil
Nom du service		: Retourne message d'accueil du portail web
But 				: Retourne message d'accueil du portail web
Facette				: GENE
Référence			: Noyau-GENE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				@iUserId					Identifiant de l'usager pour lequel on modifie la securite
						@MessageAnglais		OUT		Le message en anglais
						@MessageFrancais	OUT		Le message en francais
						
Paramètres de sortie:	
		Return :	
					0					La sp s'est executee avec succes
					Code Erreur			Une erreur geree est survenue
							
Exemple utilisation:																					

Autres infos:
	Etat :
		0 - Compte créé mais non activé par le client										
		1 - Trop de tentatives (verrouillé temporairement après 3 tentatives)				
		2 - Trop de tentatives (verrouillé en permanence après 10 tentatives)				
		3 - Compte désactivé par l'administration (verrouillé)								
		4 - Compte désactivé par le client (verrouillé)										
		5 - Aucune inscription reçue pour ce compte
		6 - Inactif (Conventions fermées)
		7 - Actif 																	
		8 - 3 réponses erronnées aux question secrètes 		

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2010-24-11		Steve Gouin							Création du service							
		2011-10-06		Eric Michaud						Ajout de NoticeFrancais et NoticeAnglais	GLPI6182
		2011-11-04		Eric Michaud						Ajout de saut de ligne a la notice			GLPI6327
		2012-05-18		Eric Michaud						Ajout Etat 8
		2013-10-08		Donald Huppé						Modifier Etat 8 : 1-877-410-REEE (7333)
		2014-01-27		Donald Huppé						modification de @NoticeFrancais et @NoticeAnglais pour une adresse invalide
		2014-05-09		Maxime Martel						Ajout des messages avec les nouvelles tables d'adresse, telephone et courriel
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_RetournerMessageAccueil]
	@iUserId					INT,
	@MessageAnglais varchar(max) output,					-- Message a retourner et afficher a l'utilisateur
	@MessageFrancais varchar(max) output,					-- Message a retourner et afficher a l'utilisateur
	@NoticeAnglais varchar(max) output,						-- Notice a retourner et afficher a l'utilisateur
	@NoticeFrancais varchar(max) output						-- Notice a retourner et afficher a l'utilisateur
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE 
		@iEtat_Courrant int,
		@LineStep VARCHAR(8)		
			
	SET @LineStep = '<br><br>'

	select 
		@iEtat_Courrant = iEtat
	from tblGENE_PortailAuthentification where iUserId = @iUserId

	-- Verifie que le status de l'usager est dans un etat qui permet une authentification
	SELECT @MessageFrancais = 
		Case 
			when @iEtat_Courrant = 0 then 'Vous n''avez pas confirmé votre inscription via le courriel des Fonds Universitas du Canada, vous avez 30 jours pour le faire.'
			when @iEtat_Courrant = 1 then 'Après plusieurs tentatives d''ouvrir une session sans succès, votre compte est présentement bloqué, veuillez réessayer plus tard.' 
			when @iEtat_Courrant = 2 then 'Après plusieurs tentatives d''ouvrir une session sans succès, votre compte est maintenant verrouillé. Veuillez contacter le Service à la clientèle au 1-877-410-REEE (7333)' 
			when @iEtat_Courrant = 3 then 'Veuillez contacter le Service à la clientèle au 1-877-410-REEE (7333)'
			when @iEtat_Courrant = 4 then 'Vous n''avez plus de conventions actives avec les Fonds Universitas du Canada'
			when @iEtat_Courrant = 6 then 'Vous devez d''abord vous inscrire au portail-client avant de pouvoir y accéder.'
			when @iEtat_Courrant = 8 then 'Après avoir échoué à répondre à vos 3 question secrètes, votre compte est maintenant verrouillé. Veuillez contacter le Service à la clientèle au 1-877-410-REEE (7333).'			
		else ''
		END

	SELECT @MessageAnglais = 
		Case 
			when @iEtat_Courrant = 0 then 'You did not confirm your registration via the e-mail from the Universitas Trust Funds of Canada; you have 30 days to do so.'
			when @iEtat_Courrant = 1 then 'After several attempts to login unsuccessfully, your account is now blocked, please try again later.'
			when @iEtat_Courrant = 2 then 'After several attempts to login unsuccessfully, your account is now locked; please contact our Customer Services at 1-877-710-RESP (7377).'
			when @iEtat_Courrant = 3 then 'Please contact our Customer Services at 1 877 710-RESP (7377).'
			when @iEtat_Courrant = 4 then 'You no longer have active agreements with the Universitas Trust Funds of Canada.'
			when @iEtat_Courrant = 6 then 'Before you can access the customer portal, you must first complete your registration.'
			when @iEtat_Courrant = 8 then 'As a result of answering your 3 secret questions incorrectly, your account is now locked; please contact our Customer Services at 1-877-710-RESP (7377).'
		else 
			''
		end

	-- Message pour cas Actif
	If @iEtat_Courrant = 5 
	BEGIN
		-- Verifier si compte transitoire Souscripteur
		if (EXISTS
			(
			select 1
			from Un_ConventionConventionState conconsta 
			inner join
				(
				SELECT 		
					ConventionConventionStateID = MAX(CCS.ConventionConventionStateID)
				FROM (-- Retourne la plus grande date de début d'un état par convention
					SELECT 
						S.ConventionID,
						MaxDate = MAX(S.StartDate)
					FROM Un_ConventionConventionState S
					JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
					WHERE S.StartDate <= getdate() -- État à la date de fin de la période
					and C.subscriberid = @iUserId 
					GROUP BY S.ConventionID
					) T
				JOIN Un_ConventionConventionState CCS ON T.ConventionID = CCS.ConventionID AND T.MaxDate = CCS.StartDate -- Retrouve l'état correspondant à la plus grande date par convention
				GROUP BY T.ConventionID
				) T1
				on conconsta.ConventionConventionStateID = T1.ConventionConventionStateID and
				conconsta.ConventionStateId = 'TRA'		
			) OR
		-- Verifier si compte transitoire Bénéficiaire
		  EXISTS
			(
			select 1
			from Un_ConventionConventionState conconsta 
			inner join
				(
				SELECT 		
					ConventionConventionStateID = MAX(CCS.ConventionConventionStateID)
				FROM (-- Retourne la plus grande date de début d'un état par convention
					SELECT 
						S.ConventionID,
						MaxDate = MAX(S.StartDate)
					FROM Un_ConventionConventionState S
					JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
					WHERE S.StartDate <= getdate() -- État à la date de fin de la période
					and C.BeneficiaryID = @iUserId 
					GROUP BY S.ConventionID
					) T
				JOIN Un_ConventionConventionState CCS ON T.ConventionID = CCS.ConventionID AND T.MaxDate = CCS.StartDate -- Retrouve l'état correspondant à la plus grande date par convention
				GROUP BY T.ConventionID
				) T1
				on conconsta.ConventionConventionStateID = T1.ConventionConventionStateID and
				conconsta.ConventionStateId = 'TRA'		
			))
		BEGIN
			set @NoticeFrancais = 'Une ou plusieurs de vos conventions sont en mode "transitoire", car le numéro d''assurance sociale (NAS) du bénéficiaire est manquant. Vous avez 1 an, suite à la signature de la convention, pour nous fournir ce numéro. Veuillez noter qu''aucun relevé de dépôts ne peut être généré pour un compte transitoire.'

			set @NoticeAnglais = 'One or more of your agreements are in a "provisional" state because the beneficiary''s Social insurance number (SIN) is missing. You have 1 year following the agreement signing to give us this number. Please note that no deposit statement can be generated for a provisional account.'

		END
		
		-- Verifier si Adresse invalide Bénéficiaire et Souscripteur
		if (EXISTS(select 1 from tblGENE_Adresse A 
			where binvalide = 1 and A.iID_Source = @iUserId and A.dtDate_Debut <= GETDATE()
			)) 
		BEGIN
			if @NoticeFrancais <> ''
				set @NoticeFrancais = 'L''adresse que nous avons à votre dossier est invalide. Veuillez mettre vos données à jour en cliquant sur l''option "Modifier votre adresse et numéro(s) de téléphone".' + @LineStep + @NoticeFrancais  
			else
				set @NoticeFrancais = 'L''adresse que nous avons à votre dossier est invalide. Veuillez mettre vos données à jour en cliquant sur l''option "Modifier votre adresse et numéro(s) de téléphone".'

			if @NoticeAnglais <> ''
				set @NoticeAnglais = 'Our system indicates that your home address is no longer valid. Please update your information by clicking on the option "Change your address and phone number(s)".' + @LineStep + @NoticeAnglais 
			else
				set @NoticeAnglais = 'Our system indicates that your home address is no longer valid. Please update your information by clicking on the option "Change your address and phone number(s)".'
			
		END
		
		--Verifier si telephone invalide
		if (EXISTS(select 1 from tblGENE_Telephone T 
			where binvalide = 1 and T.iID_Source = @iUserId and T.dtDate_Debut <= GETDATE()
			and (dtDate_Fin is null or dtDate_Fin >= GETDATE())
			)) 
		BEGIN
			if @NoticeFrancais <> ''
				set @NoticeFrancais = 'Un de vos numéros de téléphone est invalide. Veuillez mettre vos données à jour en cliquant sur l''option "Modifier votre adresse et numéro(s) de téléphone".' + @LineStep + @NoticeFrancais  
			else
				set @NoticeFrancais = 'Un de vos numéros de téléphone est invalide. Veuillez mettre vos données à jour en cliquant sur l''option "Modifier votre adresse et numéro(s) de téléphone".'

			if @NoticeAnglais <> ''
				set @NoticeAnglais = 'Our system indicates an invalid Phone Number. Please update your information by clicking on the option "Change your address and phone number(s)".' + @LineStep + @NoticeAnglais 
			else
				set @NoticeAnglais = 'Our system indicates an invalid Phone Number. Please update your information by clicking on the option "Change your address and phone number(s)".'
			
		END
		
		--Verifier si courriel invalide
		if (EXISTS(select 1 from tblGENE_Courriel T 
			where binvalide = 1 and T.iID_Source = @iUserId and T.dtDate_Debut <= GETDATE()
			and (dtDate_Fin is null or dtDate_Fin >= GETDATE()) 
			)) 
		BEGIN
			if @NoticeFrancais <> ''
				set @NoticeFrancais = 'Votre courriel est invalide. Veuillez mettre vos données à jour en cliquant sur le lien "Modifier".' + @LineStep + @NoticeFrancais  
			else
				set @NoticeFrancais = 'Votre courriel est invalide. Veuillez mettre vos données à jour en cliquant sur le lien "Modifier".'

			if @NoticeAnglais <> ''
				set @NoticeAnglais = 'Your email is invalid. Please update your information by clicking on the "Change" link.' + @LineStep + @NoticeAnglais 
			else
				set @NoticeAnglais = 'Your email is invalid. Please update your information by clicking on the "Change" link.'
			
		END
	END	

END


