/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psGENE_EnregistrerSecurite
Nom du service		: Enregistrer la securite
But 				: Créer ou mettre à jour les paramètres d'authentification d'un usager
Facette				: GENE
Référence			: Noyau-GENE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				@iUserId					Identifiant de l'usager pour lequel on modifie la securite
						@dtDateNaissance			Date de naissance pour validation seulement lors de la creation du compte
						@vbMotPasse					Mot de passe usager
						@vbMotPasse_Nouveau			Nouveau mot de passe a inscrire
						@vcCourriel					Nouveau courriel de l'utilisateur 
						@iQSid1						Id question secrete 1
						@iQSid2						Id question secrete 2
						@iQSid3						Id question secrete 3
						@vbRQ1						Response a la question secrete 1
						@vbRQ2						Response a la question secrete 2
						@vbRQ3						Response a la question secrete 3
						@vbCleConfirmationMD5		Cle de confirmation web

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------

Exemple utilisation:																					
	- Creation d'un compte ou MAJ d'un compte
		EXEC psGENE_EnregistrerSecurite 1, '12 sep 1965',<MotPasse_Actuel>,null, 'steve.gouin@universitas.com', 1, 'Lafleur', 2, 'St-Hurbain', 3, 'Laval', 0x2

	- MAJ du mot de passe en connaissant ancien mot de passe
		EXEC psGENE_EnregistrerSecurite 1, null, <MotPasse_Actuel>, <MotPasse_Nouveau>
		
	- MAJ du mot de passe en ignorant ancien mot de passe sur base question secrete
		EXEC psGENE_EnregistrerSecurite 1, null, null, <MotPasse_Nouveau>,null, 3, 'Laval'

	- MAJ du courriel forcer la validation
		EXEC psGENE_EnregistrerSecurite 1, null, <MotPasse_Actuel>,null, 'steve.gouin2@universitas.com', null,null,null,null,null,null,0x3
	
TODO:
	- Vérifier la date de naissance lors d'une réinscription
	- Generer une note lors du changement d'adresse email
	- Phase 2 : Remettre la validation sur les questions secretes

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2010-08-10		Steve Gouin					Création du service							
		2011-05-19		Pierre-Luc Simard			Remettre le consentement à NULL après chaque inscription 
																	ou réinscription
		2011-11-10		Eric Michaud					Modification date de naissance, retirer l'obligation 
																	d'entrer le même mot de passe   GLPI5972
		2011-11-18		Eric Michaud					Mettre des codes pour les messages
		2012-08-30		Eric Michaud					Dans le cas 7 remettre l’état a 0 et mettre la date du jours a la date d’inscription
		2014-02-20		Pierre-luc Simard			bConsentement n'est plus mis à NULL après une inscription au Portail
		2014-03-12		Pierre-Luc Simard			Appeler la procédure SP_IU_CRQ_Adr au lieu de IMo_Adr
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_EnregistrerSecurite]
	@iUserId					INT,
	@dtDateNaissance			datetime = null,
	@vbMotPasse					varbinary(100) = null,
	@vbMotPasse_Nouveau			varbinary(100) = NULL,
	@vcCourriel					varchar(100) = null,
	@iQS1id						INT = NULL,
	@vbRQ1						varbinary(100) = NULL,
	@iQS2id						INT = NULL,
	@vbRQ2						varbinary(100) = NULL,
	@iQS3id						INT = NULL,
	@vbRQ3						varbinary(100) = NULL,
	@vbCleConfirmationMD5		varbinary(100) = null
	
AS
BEGIN
	SET NOCOUNT ON;

	-- 
	-- Initialisation
	--
	
	-- Usager info
	Declare 
		@vbMotPasse_Courrant varbinary(100),
		@iEtat_Courrant int,
		@dtDernierAcces_Courrant datetime,
		@iCompteurEssais_Courrant int,
		@vbCleConfirmationMD5_Courrant varbinary(100)
		
	select 
		@vbMotPasse_Courrant = vbMotPasse,
		@iEtat_Courrant = iEtat,
		@dtDernierAcces_Courrant = dtDernierAcces,
		@iCompteurEssais_Courrant = iCompteurEssais,
		@vbCleConfirmationMD5_Courrant = vbCleConfirmationMD5
	from 
		tblGENE_PortailAuthentification
	where 
		iUserId = @iUserId
			
	--
	-- Validation
	--
	
	-- Verifier que le iUserId est un humain valide
	if not exists(select 1 FROM dbo.Mo_Human where Humanid = @iUserId)
	BEGIN
		-- L'usager spécifié n'existe pas dans le système.
		RAISERROR('err_enregistrersecuritemessage1',15,1)
		RETURN 100
	END
	
	---- Verifier si c'est un compte deja existant pour valider les acces

	if	@iEtat_Courrant is not null	and @iEtat_Courrant <> 7								
	BEGIN
--		if (isnull(@vbMotPasse,0x0) <> isnull(@vbMotPasse_Courrant,0x0)) and			-- Mot de passe ne correspondent pas
--			@vbMotPasse is not null
--		BEGIN
			--select @vbMotPasse, @vbMotPasse_Courrant, @iQS1id, @vbRQ1, @iQS2id, @vbRQ2, @iQS3id,@vbRQ3, @iUserId
			-- Le mot de passe spécifié ne correspond pas.
--			RAISERROR('err_enregistrersecuritemessage2',15,1)
--			RETURN 200
--		END

		--select @vbMotPasse, @vbMotPasse_Courrant, @iQS1id, @vbRQ1, @iQS2id, @vbRQ2, @iQS3id,@vbRQ3, @iUserId
		-- Le compte n'est pas dans un état qui lui permet d'être mis a jour.
		RAISERROR('err_enregistrersecuritemessage3',15,1)
		RETURN 205
		
	END
	
	--
	-- A reactiver en phase 2 a la place du if ci haut, 
	-- afin  que la validation de la reponse secrete se fasse dans la BD et non dans le service web pour des raisons de securite.
	--

	--if	@iEtat_Courrant is not null									
	--BEGIN
	--	if (isnull(@vbMotPasse,0x0) <> isnull(@vbMotPasse_Courrant,0x0)) and			-- Mot de passe ne correspondent pas
	--		not exists																	-- Aucune question secrète ne correspond
	--		(
	--		select 1 from tblGENE_PortailAuthentification 
	--		where 
	--			(
	--				(iQS1id =@iQS1id and vbRQ1 = @vbRQ1) or 
	--				(iQS2id =@iQS1id and vbRQ2 = @vbRQ1) or 
	--				(iQS3id =@iQS1id and vbRQ3 = @vbRQ1)
	--			)  
	--			and iUserId = @iUserId
	--		)
	--	BEGIN
	--		--select @vbMotPasse, @vbMotPasse_Courrant, @iQS1id, @vbRQ1, @iQS2id, @vbRQ2, @iQS3id,@vbRQ3, @iUserId
	--		RETURN 200
	--	END
	--END

	--
	-- Principal
	--

	-- Verifier que le iUserId est un humain valide et que la date de naissance correspond
	if not exists(select 1 FROM dbo.Mo_Human where Humanid = @iUserId and BirthDate = @dtDateNaissance)
	BEGIN
		-- La date de naissance ne correspond pas à l'usager spécifié.
		RAISERROR('err_enregistrersecuritemessage4',15,1)
		RETURN 110
	END

	if	@iEtat_Courrant is null									
	BEGIN
			
		-- Nouvelle securite a ajouter
		INSERT INTO [tblGENE_PortailAuthentification]
				   ([iUserId]
				   ,[vbMotPasse]
				   ,[iEtat]
				   ,[iQS1id]
				   ,[iQS2id]
				   ,[iQS3id]
				   ,[vbRQ1]
				   ,[vbRQ2]
				   ,[vbRQ3]
		--		   ,[dtDernierAcces]
				   ,[iCompteurEssais]
				   ,[vbCleConfirmationMD5])
			 VALUES
				   (
				   @iUserId,
				   isnull(@vbMotPasse_Nouveau,@vbMotPasse),
				   0,
				   @iQS1id,
				   @iQS2id,
				   @iQS3id,
				   @vbRQ1,
				   @vbRQ2,
				   @vbRQ3,
		--		   getdate(),
				   0,
				   @vbCleConfirmationMD5
				   )
				   		
	END
	ELSE 
	BEGIN
		
		-- MAJ de la securite actuelle
		Update tblGENE_PortailAuthentification
		SET 
			vbMotPasse = isnull(isnull(@vbMotPasse_Nouveau,@vbMotPasse),vbMotPasse),
--			iEtat = Case when vbCleConfirmationMD5 <> @vbCleConfirmationMD5 then 0 else iEtat end,	-- Remet Etat a 0 si nouvelle cle md5 specifie
			iEtat = 0,	-- Remet Etat a 0 si nouvelle cle md5 specifie
			iQS1Id = isnull(@iQS1Id,iQS1Id),
			iQS2Id = isnull(@iQS2Id,iQS2Id),
			iQS3Id = isnull(@iQS3Id,iQS3Id),
			vbRQ1 = isnull(@vbRQ1,vbRQ1),
			vbRQ2 = isnull(@vbRQ2,vbRQ2),
			vbRQ3 = isnull(@vbRQ3,vbRQ3),
			dtinscription = getdate(),
			dtdernieracces = NULL,
			iCompteurEssais = 0,
			vbCleConfirmationMD5 = isnull(@vbCleConfirmationMD5, vbCleConfirmationMD5)
		WHERE
			iUserId = @iUserId
		
	END	

	-- Modifier l'adresse de courriel dans la table ou elle reside si différente
	if @vcCourriel is not null and @vcCourriel <> (select isnull(Email,'') FROM dbo.Mo_Adr  where adrid = (select adrid FROM dbo.Mo_Human where Humanid = @iUserId))
	BEGIN

		-- Creation de l'adresse sur base de celle existante
		DECLARE 
			@AdrId int,		
			@Address VARCHAR(75),
			@City VARCHAR(100),
			@StateName VARCHAR(75),
			@CountryID CHAR(4),
			@ZipCode VARCHAR(10),
			@Phone1 VARCHAR(27),
			@Phone2 VARCHAR(27),
			@Fax VARCHAR(15),
			@Mobile VARCHAR(15),
			@WattLine VARCHAR(27),
			@OtherTel VARCHAR(27),
			@Pager VARCHAR(15)

		SELECT @AdrId = adrId FROM dbo.Mo_Human where Humanid = @iUserId

		SELECT 
			@Address = Address,
			@City = City,
			@StateName = StateName,
			@CountryID = CountryID,
			@ZipCode = ZipCode,
			@Phone1 = Phone1,
			@Phone2 = Phone2,
			@Fax = Fax,
			@Mobile = Mobile,
			@WattLine = WattLine,
			@OtherTel = OtherTel,
			@Pager = Pager
		FROM dbo.Mo_Adr 
		where adrid = @AdrId
		
		DECLARE @iID_Utilisateur_Systeme INT
		SELECT TOP 1 @iID_Utilisateur_Systeme = D.iID_Utilisateur_Systeme FROM Un_Def D

		DECLARE @DateDuJour datetime
		set @DateDuJour = getdate()

		EXEC @AdrID = SP_IU_CRQ_Adr --IMo_Adr
			@ConnectID = @iID_Utilisateur_Systeme,
			@AdrID = @AdrId,
			@InForce = @DateDuJour,
			@AdrTypeID = 'H',
			@SourceID = @iUserId,
			@Address = @Address,
			@City = @City,
			@StateName = @StateName,
			@CountryID = @CountryID,
			@ZipCode = @ZipCode,
			@Phone1 = @Phone1,
			@Phone2 = @Phone2,
			@Fax = @Fax,
			@Mobile = @Mobile,
			@WattLine = @WattLine,
			@OtherTel = @OtherTel,
			@Pager = @Pager,
			@Email = @vcCourriel

		-- Mettre a jour la nouvelle adresse de l'humain
		UPDATE dbo.Mo_Human set adrid = @AdrID where Humanid = @iUserId

		-- Remplace toutes les adresses futures par cette nouvelle adresse
		/*
		UPDATE dbo.Mo_Adr  
		set Email = @vcCourriel
		where SourceId = @iUserId and
			inForce >getdate() 
		*/
	
	END	

	-- Remettre le consentement à NULL après chaque inscription ou réinscription
	-- Souscripteur	
	--	UPDATE dbo.Un_Subscriber set bConsentement = NULL where subscriberid = @iUserId		
	-- Bénéficiaire
	--	UPDATE dbo.Un_Beneficiary set bConsentement = NULL where beneficiaryid = @iUserId

END


