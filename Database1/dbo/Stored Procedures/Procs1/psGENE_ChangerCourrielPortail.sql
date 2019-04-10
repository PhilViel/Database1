/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psGENE_ChangerCourrielPortail
Nom du service		: Enregistrer la securite
But 				: Créer ou mettre à jour le courriel de l'usager
Facette				: GENE
Référence			: Noyau-GENE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				@iUserId					Identifiant de l'usager 
						@vcCourriel					Nouveau courriel de l'utilisateur 

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------

Exemple utilisation:																					
	- modification courriel
		EXEC psGENE_ChangerCourrielPortail 1, 'steve.gouin@universitas.com'
			
TODO:

Historique des modifications:
		Date				Programmeur							Description									Référence
		------------		-------------------------	-----------------------------------------	------------
		2011-12-08	Eric Michaud				Création du service	a partir de psGENE_EnregistrerSecurite
		2014-03-12	Pierre-Luc Simard		Appeler SP_IU_CRQ_Adr au lieu de IMo_Adr						
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_ChangerCourrielPortail]
	@iUserId					INT,
	@vcCourriel					varchar(100)
	
AS
BEGIN
	SET NOCOUNT ON;
		
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
		SELECT TOP 1 @iID_Utilisateur_Systeme = CASE WHEN S.SubscriberID IS NOT NULL THEN MCS.ConnectID ELSE MCb.ConnectID END
		FROM dbo.Mo_Human H
				LEFT JOIN dbo.Un_Subscriber S ON S.SubscriberID = H.HumanID
				LEFT JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = H.HumanID
				JOIN tblGENE_TypesParametre TPS ON TPS.vcCode_Type_Parametre = 'GENE_AUTHENTIFICATION_SOUSC_CONNECTID' 
				JOIN tblGENE_Parametres PS ON TPS.iID_Type_Parametre = PS.iID_Type_Parametre
				JOIN tblGENE_TypesParametre TPB ON TPB.vcCode_Type_Parametre = 'GENE_AUTHENTIFICATION_BENEF_CONNECTID'
				JOIN tblGENE_Parametres PB ON TPB.iID_Type_Parametre = PB.iID_Type_Parametre
				JOIN Mo_Connect MCS ON PS.vcValeur_Parametre = MCS.ConnectID
				JOIN Mo_Connect MCB ON PB.vcValeur_Parametre = MCB.ConnectID
		WHERE H.HumanID = @iUserId

		DECLARE @DateDuJour datetime
		set @DateDuJour = getdate()

		EXEC @AdrID = SP_IU_CRQ_Adr
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
		UPDATE dbo.Mo_Adr  
		set Email = @vcCourriel
		where SourceId = @iUserId and
			inForce >getdate() 
	END	

END


