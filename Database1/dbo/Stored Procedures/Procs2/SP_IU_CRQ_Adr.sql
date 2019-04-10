/****************************************************************************************************
Copyrights (c) 2003 Compurangers .Inc
Nom                 :	SP_IU_CRQ_Adr
Description         :	Sauvegarde d'ajout ou de mise à jour d'adresse.
Valeurs de retours  :	@ReturnValue :
									>0 :	La sauvegarde a réussie.  La valeur de retour correspond au AdrID de
											l’adresse sauvegardée.
									<=0 :	La sauvegarde a échouée.

Note :				ADX0001080	BR	2004-09-21	Bruno Lapointe		Permet de sauvegarder l'adresse même s'il n'y a que le pays de remplis.
						ADX0001130	BR	2004-10-28	Bruno Lapointe		Enlève le formatage des numéros de téléphones ADX0000590	IA	2004-11-19	Bruno Lapointe		Renommée.  Modifié pour qu’elle crée une nouvelle
																								adresse lors de modification plutôt que de
																								modifier celle existante afin de créer l'historique
						ADX0001602	BR	2005-10-11	Bruno Lapointe		SCOPE_IDENTITY au lieu de IDENT_CURRENT
						ADX0001278	IA	2007-03-19	Alain Quirion			Vérification de la province en plus du pays pour la fusion des villes
										2008-11-19	Donald Huppé			Comparaison des valeurs binaires pour le champ address pour gérer les majuscules et minuscules
										2014-02-12	Pierre-Luc Simard	Insertion des adresses dans les nouvelles tables
										2014-06-03	Pierre-Luc Simard	Type téléphone cellulaire est 2 et non 5
										2015-06-30  Steve Picard		Désactive les triggers TRG_GENE_Telephone_Historisation
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SP_IU_CRQ_Adr] (
	@ConnectID INTEGER,
	@AdrID INTEGER,
	@InForce DATETIME,
	@AdrTypeID MoAdrType,
	@SourceID INTEGER,
	@Address VARCHAR(75) = NULL,
	@City VARCHAR(100) = NULL,
	@StateName VARCHAR(75) = NULL,
	@CountryID CHAR(4) = NULL,
	@ZipCode VARCHAR(10) = NULL,
	@Phone1 VARCHAR(27) = NULL,
	@Phone2 VARCHAR(27) = NULL,
	@Fax VARCHAR(15) = NULL,
	@Mobile VARCHAR(15) = NULL,
	@WattLine VARCHAR(27) = NULL,
	@OtherTel VARCHAR(27) = NULL,
	@Pager VARCHAR(15) = NULL,
	@EMail VARCHAR(100) = NULL)
AS
BEGIN
	-- Valeurs de retour
	-- >0   : Tout a fonctionné. Valeur = ID de l'adresse inséré (AdrID)
	-- <= 0 : Erreur
	--	0	: Erreur à l'insertion de l'adresse

	DECLARE
		@DateNull DATETIME,
		@OldInForce DATETIME,
		@OldAddress VARCHAR(75),
		@OldCity VARCHAR(100),
		@OldStateName VARCHAR(75),
		@OldCountryID CHAR(4),
		@OldZipCode VARCHAR(10),
		@OldPhone1 VARCHAR(27),
		@OldPhone2 VARCHAR(27),
		@OldFax VARCHAR(15),
		@OldMobile VARCHAR(15),
		@OldWattLine VARCHAR(27),
		@OldOtherTel VARCHAR(27),
		@OldPager VARCHAR(15),
		@OldEMail VARCHAR(100),
		@vcLogin_Creation VARCHAR(50),
		@iID_Ville INT,
		@iID_Province INT,
		@vcPays VARCHAR(75),
		@vcTelAutre VARCHAR(27)
			
	IF object_id('tempdb..#DisableTrigger') is null
		CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))
		
	-- Met les valeurs
	SET @Phone1 = dbo.FN_CRQ_GetNumberOfStringOnly(@Phone1)
	SET @Phone2 = dbo.FN_CRQ_GetNumberOfStringOnly(@Phone2)
	SET @Fax = dbo.FN_CRQ_GetNumberOfStringOnly(@Fax)
	SET @Mobile = dbo.FN_CRQ_GetNumberOfStringOnly(@Mobile)
	SET @WattLine = dbo.FN_CRQ_GetNumberOfStringOnly(@WattLine)
	SET @OtherTel = dbo.FN_CRQ_GetNumberOfStringOnly(@OtherTel)
	SET @Pager = dbo.FN_CRQ_GetNumberOfStringOnly(@Pager)

	IF RTRIM(@StateName) = ''
		SET @StateName = NULL

	IF RTRIM(@City) = ''
		SET @City = NULL
		
	IF @InForce <= GETDATE() OR @InForce = NULL
		SET @InForce = GETDATE()
		
	-- Va chercher le login selon le ConnectID
	SELECT @vcLogin_Creation = U.LoginNameID 
	FROM Mo_Connect C
	JOIN Mo_User U ON U.UserID = C.UserID
	WHERE C.ConnectID = @ConnectID

	-- Si aucune donnée d'adresse il n'en crée pas inutilement.
	IF (((@Address IS NULL) OR (RTRIM(@Address) = '')) AND
		 ((@City IS NULL) OR (RTRIM(@City) = '')) AND
		 ((@StateName IS NULL) OR (RTRIM(@StateName) = '')) AND
		 ((@CountryID IS NULL) OR (RTRIM(@CountryID) = '')) AND
		 ((@ZipCode IS NULL) OR (RTRIM(@ZipCode) = '')) AND
		 ((@AdrID IS NULL) OR (@AdrID = 0)) )
		SET @AdrID = 0
	ELSE
	BEGIN
		IF @AdrID > 0
		BEGIN
			-- Va chercher les valeurs de la base de données avant de modifié pour comparer avec celles envoyés en paramètre
			SELECT
				@OldAddress = Address,
				@OldCity = City,
				@OldStateName = StateName,
				@OldCountryID = CountryID,
				@OldZipCode = ZipCode,
				@OldPhone1 = Phone1,
				@OldPhone2 = Phone2,
				@OldFax = Fax,
				@OldMobile = Mobile,
				@OldWattLine = WattLine,
				@OldOtherTel = OtherTel,
				@OldPager = Pager,
				@OldEMail = EMail
			FROM dbo.Mo_Adr 
			WHERE AdrID = @AdrID
				
			-- Si rien n'a changé, il ne crée pas d'historique. 
			-- Pour le champs Address, on compare les valeurs binaires au cas où la diff avec l'ancienne valeur ne concerne que des majuscules ou minuscules
			IF ((CAST(LTRIM(RTRIM(ISNULL(@Address, ''))) as varbinary(100)) <> CAST(LTRIM(RTRIM(ISNULL(@OldAddress, ''))) as varbinary(100))) OR
				 (LTRIM(RTRIM(ISNULL(@City, ''))) <> LTRIM(RTRIM(ISNULL(@OldCity, '')))) OR
				 (LTRIM(RTRIM(ISNULL(@StateName, ''))) <> LTRIM(RTRIM(ISNULL(@OldStateName, '')))) OR
				 (LTRIM(RTRIM(ISNULL(@CountryID, ''))) <> LTRIM(RTRIM(ISNULL(@OldCountryID, '')))) OR
				 (LTRIM(RTRIM(ISNULL(@ZipCode, ''))) <> LTRIM(RTRIM(ISNULL(@OldZipCode, '')))) ) 
				SET @AdrID = 0
		END

		IF @AdrID = 0
		BEGIN
			------------------------------------------------------------------------
			-- Recherche d'une fusion existante pour le nom de ville en paramètre --
			------------------------------------------------------------------------
			IF EXISTS (
					SELECT *
					FROM Mo_CityFusion F
					LEFT JOIN Mo_State S ON S.StateID = F.StateID
					JOIN Mo_City C ON C.CityID = F.CityID
					WHERE F.OldCityName = @City
					  AND C.CountryID = @CountryID			 
					  AND ISNULL(S.StateName,'') = ISNULL(@StateName,''))
			BEGIN
				SELECT 
					@City = C.CityName
				FROM Mo_CityFusion F
				LEFT JOIN Mo_State S ON S.StateID = F.StateID
				JOIN Mo_City C ON C.CityID = F.CityID		
				WHERE F.OldCityName = @City
					AND C.CountryID = @CountryID	
					AND ISNULL(S.StateName,'') = ISNULL(@StateName,'')
			END
		
			-- Va chercher l'ID de la province selon le nom de la province
			SELECT @iID_Province = S.StateID
			FROM Mo_State S
			WHERE S.StateName = @StateName
				AND S.CountryID = @CountryID
							
			-- Va chercher l'ID de la ville selon le nom de la ville
			SELECT @iID_Ville = C.CityID 
			FROM Mo_City C
			WHERE C.CityName = @City
				AND C.CountryID = @CountryID
				AND C.StateID = @iID_Province
			
			-- Va chercher le nom du pays selon l'ID du pays
			SELECT @vcPays = C.CountryName
			FROM Mo_Country C
			WHERE C.CountryID = @CountryID
			
			-- Insère l'adresse
			INSERT INTO tblGENE_Adresse (
				iID_Source,
			    cType_Source,
			    iID_Type,
			    dtDate_Debut,
			    bInvalide,
			    dtDate_Creation,
			    vcLogin_Creation,
			    vcNumero_Civique,
			    vcNom_Rue,
			    vcUnite,
			    vcCodePostal,
			    vcBoite,
			    iID_TypeBoite,
			    iID_Ville,
			    vcVille,
			    iID_Province,
			    vcProvince,
			    cID_Pays,
				vcPays, 
			    bNouveau_Format,
			    bResidenceFaitQuebec,
			    bResidenceFaitCanada,
			    vcInternationale1,
			    vcInternationale2,
			    vcInternationale3)
			VALUES (
				@SourceID,
			    @AdrTypeID,
			    1,
			    @InForce,
			    0,
			    GETDATE(),
			    @vcLogin_Creation,
			    NULL,
			    @Address,
			    NULL,
			    @ZipCode,
			    NULL,
			    0,
			    ISNULL(@iID_Ville, NULL),
			    @City,
			    @iID_Province,
			    @StateName,
			    @CountryID,
				@vcPays, 
			    0,
			    0,
			    0,
			    NULL,
			    NULL,
			    NULL)
		
			IF @@ERROR = 0
				SET @AdrID = SCOPE_IDENTITY()
			ELSE
				SET @AdrID = 0
			
			-- Va chercher les valeurs de la base de données avant de modifié pour comparer avec celles envoyés en paramètre
			SELECT
				@OldPhone1 = Phone1,
				@OldPhone2 = Phone2,
				@OldFax = Fax,
				@OldMobile = Mobile,
				@OldWattLine = WattLine,
				@OldOtherTel = OtherTel,
				@OldPager = Pager,
				@OldEMail = EMail
			FROM dbo.Mo_Adr 
			WHERE SourceID = @SourceID
		
		END
	END

	INSERT INTO #DisableTrigger VALUES('TRG_GENE_Telephone_Historisation_D')	
	
	-- Téléphone de type Résidence
	IF LTRIM(RTRIM(ISNULL(@Phone1, ''))) <> LTRIM(RTRIM(ISNULL(@OldPhone1, '')))
		BEGIN 
			-- On inscrit une date de fin pour l'ancien téléphone si sa date de début est différente de celle du jour
			UPDATE tblGENE_Telephone 
			SET dtDate_Fin = dbo.FN_CRQ_DateNoTime(@InForce)	
			WHERE iID_Source = @SourceID
				AND iID_Type = 1
				AND dbo.FN_CRQ_DateNoTime(dtDate_Debut) <> dbo.FN_CRQ_DateNoTime(@InForce)	
				AND dtDate_Fin IS NULL
				AND LTRIM(RTRIM(ISNULL(vcTelephone, ''))) + ISNULL(vcExtension, '') = LTRIM(RTRIM(ISNULL(@OldPhone1, '')))
			
			-- Si la date de début de l'ancien téléphone est le même jour, on supprime ce dernier
			DELETE dbo.tblGENE_Telephone
			WHERE iID_Source = @SourceID
				AND iID_Type = 1
				AND dbo.FN_CRQ_DateNoTime(dtDate_Debut) = dbo.FN_CRQ_DateNoTime(@InForce)	
				AND LTRIM(RTRIM(ISNULL(vcTelephone, ''))) + ISNULL(vcExtension, '') = LTRIM(RTRIM(ISNULL(@OldPhone1, '')))
		
			-- Le nouveau téléphone est ajouté, s'il y en a un		
			IF LTRIM(RTRIM(ISNULL(@Phone1, ''))) <> ''
				INSERT INTO tblGENE_Telephone(
					iID_Source,
					cType_Source,
					vcTelephone,
					vcExtension,
					iID_Type,
					dtDate_Debut,
					dtDate_Fin,
					bPublic,
					bInvalide,
					dtDate_Creation,
					vcLogin_Creation)
				VALUES (
					@SourceID,
					@AdrTypeID,
					SUBSTRING(LTRIM(@Phone1), 1, 10),
					CASE WHEN LEN(LTRIM(RTRIM(@Phone1))) > 10 THEN  SUBSTRING(LTRIM(@Phone1), 11, LEN(LTRIM(RTRIM(@Phone1))) - 10) ELSE NULL END,
					1,
					dbo.FN_CRQ_DateNoTime(@InForce),
					NULL,
					1,
					0,
					GETDATE(),
					@vcLogin_Creation)
		END
		
	-- Téléphone de type Travail
		IF LTRIM(RTRIM(ISNULL(@Phone2, ''))) <> LTRIM(RTRIM(ISNULL(@OldPhone2, '')))
		BEGIN 
			-- On inscrit une date de fin pour l'ancien téléphone si sa date de début est différente de celle du jour
			UPDATE tblGENE_Telephone 
			SET dtDate_Fin = dbo.FN_CRQ_DateNoTime(GETDATE())	
			WHERE iID_Source = @SourceID
				AND iID_Type = 4
				AND dbo.FN_CRQ_DateNoTime(dtDate_Debut) <> dbo.FN_CRQ_DateNoTime(GETDATE())
				AND dtDate_Fin IS NULL
				AND LTRIM(RTRIM(ISNULL(vcTelephone, ''))) + ISNULL(vcExtension, '') = LTRIM(RTRIM(ISNULL(@OldPhone2, '')))
			
			-- Si la date de début de l'ancien téléphone est le même jour, on supprime ce dernier
			DELETE dbo.tblGENE_Telephone
			WHERE iID_Source = @SourceID
				AND iID_Type = 4
				AND dbo.FN_CRQ_DateNoTime(dtDate_Debut) = dbo.FN_CRQ_DateNoTime(GETDATE())
				AND LTRIM(RTRIM(ISNULL(vcTelephone, ''))) + ISNULL(vcExtension, '') = LTRIM(RTRIM(ISNULL(@OldPhone2, '')))
		
			-- Le nouveau téléphone est ajouté, s'il y en a un		
			IF LTRIM(RTRIM(ISNULL(@Phone2, ''))) <> ''
				INSERT INTO tblGENE_Telephone(
					iID_Source,
					cType_Source,
					vcTelephone,
					vcExtension,
					iID_Type,
					dtDate_Debut,
					dtDate_Fin,
					bPublic,
					bInvalide,
					dtDate_Creation,
					vcLogin_Creation)
				VALUES (
					@SourceID,
					@AdrTypeID,
					SUBSTRING(LTRIM(@Phone2), 1, 10),
					CASE WHEN LEN(LTRIM(RTRIM(@Phone2))) > 10 THEN  SUBSTRING(LTRIM(@Phone2), 11, LEN(LTRIM(RTRIM(@Phone2))) - 10) ELSE NULL END,
					4,
					dbo.FN_CRQ_DateNoTime(@InForce),
					NULL,
					1,
					0,
					GETDATE(),
					@vcLogin_Creation)
		END
		
	-- Téléphone de type Cellulaire
	IF LTRIM(RTRIM(ISNULL(@Mobile, ''))) <> LTRIM(RTRIM(ISNULL(@OldMobile, '')))
		BEGIN 
			-- On inscrit une date de fin pour l'ancien téléphone si sa date de début est différente de celle du jour
			UPDATE tblGENE_Telephone 
			SET dtDate_Fin = dbo.FN_CRQ_DateNoTime(GETDATE())	
			WHERE iID_Source = @SourceID
				AND iID_Type = 2
				AND dbo.FN_CRQ_DateNoTime(dtDate_Debut) <> dbo.FN_CRQ_DateNoTime(GETDATE())
				AND dtDate_Fin IS NULL
				AND LTRIM(RTRIM(ISNULL(vcTelephone, ''))) + ISNULL(vcExtension, '') = LTRIM(RTRIM(ISNULL(@OldMobile, '')))
			
			-- Si la date de début de l'ancien téléphone est le même jour, on supprime ce dernier
			DELETE dbo.tblGENE_Telephone
			WHERE iID_Source = @SourceID
				AND iID_Type = 2
				AND dbo.FN_CRQ_DateNoTime(dtDate_Debut) = dbo.FN_CRQ_DateNoTime(GETDATE())
				AND LTRIM(RTRIM(ISNULL(vcTelephone, ''))) + ISNULL(vcExtension, '') = LTRIM(RTRIM(ISNULL(@OldMobile, '')))
		
			-- Le nouveau téléphone est ajouté, s'il y en a un		
			IF LTRIM(RTRIM(ISNULL(@Mobile, ''))) <> ''
				INSERT INTO tblGENE_Telephone(
					iID_Source,
					cType_Source,
					vcTelephone,
					vcExtension,
					iID_Type,
					dtDate_Debut,
					dtDate_Fin,
					bPublic,
					bInvalide,
					dtDate_Creation,
					vcLogin_Creation)
				VALUES (
					@SourceID,
					@AdrTypeID,
					SUBSTRING(LTRIM(@Mobile), 1, 10),
					CASE WHEN LEN(LTRIM(RTRIM(@Mobile))) > 10 THEN  SUBSTRING(LTRIM(@Mobile), 11, LEN(LTRIM(RTRIM(@Mobile))) - 10) ELSE NULL END,
					2,
					dbo.FN_CRQ_DateNoTime(@InForce),
					NULL,
					1,
					0,
					GETDATE(),
					@vcLogin_Creation)
		END

	-- Téléphone de type Télécopieur
		IF LTRIM(RTRIM(ISNULL(@Fax, ''))) <> LTRIM(RTRIM(ISNULL(@OldFax, '')))
		BEGIN 
			-- On inscrit une date de fin pour l'ancien téléphone si sa date de début est différente de celle du jour
			UPDATE tblGENE_Telephone 
			SET dtDate_Fin = dbo.FN_CRQ_DateNoTime(GETDATE())	
			WHERE iID_Source = @SourceID
				AND iID_Type = 8
				AND dbo.FN_CRQ_DateNoTime(dtDate_Debut) <> dbo.FN_CRQ_DateNoTime(GETDATE())
				AND dtDate_Fin IS NULL
				AND LTRIM(RTRIM(ISNULL(vcTelephone, ''))) + ISNULL(vcExtension, '') = LTRIM(RTRIM(ISNULL(@OldFax, '')))
			
			-- Si la date de début de l'ancien téléphone est le même jour, on supprime ce dernier
			DELETE dbo.tblGENE_Telephone
			WHERE iID_Source = @SourceID
				AND iID_Type = 8
				AND dbo.FN_CRQ_DateNoTime(dtDate_Debut) = dbo.FN_CRQ_DateNoTime(GETDATE())
				AND LTRIM(RTRIM(ISNULL(vcTelephone, ''))) + ISNULL(vcExtension, '') = LTRIM(RTRIM(ISNULL(@OldFax, '')))
		
			-- Le nouveau téléphone est ajouté, s'il y en a un		
			IF LTRIM(RTRIM(ISNULL(@Fax, ''))) <> ''
				INSERT INTO tblGENE_Telephone(
					iID_Source,
					cType_Source,
					vcTelephone,
					vcExtension,
					iID_Type,
					dtDate_Debut,
					dtDate_Fin,
					bPublic,
					bInvalide,
					dtDate_Creation,
					vcLogin_Creation)
				VALUES (
					@SourceID,
					@AdrTypeID,
					SUBSTRING(LTRIM(@Fax), 1, 10),
					CASE WHEN LEN(LTRIM(RTRIM(@Fax))) > 10 THEN  SUBSTRING(LTRIM(@Fax), 11, LEN(LTRIM(RTRIM(@Fax))) - 10) ELSE NULL END,
					8,
					dbo.FN_CRQ_DateNoTime(@InForce),
					NULL,
					1,
					0,
					GETDATE(),
					@vcLogin_Creation)
		END

	-- Téléphone de type Autre (Le premier parmis Autre, Pagette et Sans-Frais)  
	SET @vcTelAutre = COALESCE(@OtherTel, @Pager, @WattLine)
	
	IF LTRIM(RTRIM(ISNULL(@OtherTel, ''))) <> LTRIM(RTRIM(ISNULL(@OldOtherTel, '')))
		OR LTRIM(RTRIM(ISNULL(@Pager, ''))) <> LTRIM(RTRIM(ISNULL(@OldPager, '')))
		OR LTRIM(RTRIM(ISNULL(@WattLine, ''))) <> LTRIM(RTRIM(ISNULL(@OldWattLine, '')))
	BEGIN
		SET @vcTelAutre = COALESCE(@OtherTel, @Pager, @WattLine)
							
		-- On inscrit une date de fin pour l'ancien téléphone si sa date de début est différente de celle du jour
		UPDATE tblGENE_Telephone 
		SET dtDate_Fin = dbo.FN_CRQ_DateNoTime(GETDATE())	
		WHERE iID_Source = @SourceID
			AND iID_Type = 16
			AND dbo.FN_CRQ_DateNoTime(dtDate_Debut) <> dbo.FN_CRQ_DateNoTime(GETDATE())
			AND dtDate_Fin IS NULL
			AND (LTRIM(RTRIM(ISNULL(vcTelephone, ''))) + ISNULL(vcExtension, '') = LTRIM(RTRIM(ISNULL(@OldOtherTel, '')))
				OR LTRIM(RTRIM(ISNULL(vcTelephone, ''))) + ISNULL(vcExtension, '') = LTRIM(RTRIM(ISNULL(@OldPager, '')))
				OR LTRIM(RTRIM(ISNULL(vcTelephone, ''))) + ISNULL(vcExtension, '') = LTRIM(RTRIM(ISNULL(@OldWattLine, ''))))
		
		-- Si la date de début de l'ancien téléphone est le même jour, on supprime ce dernier
		DELETE dbo.tblGENE_Telephone
		WHERE iID_Source = @SourceID
			AND iID_Type = 16
			AND dbo.FN_CRQ_DateNoTime(dtDate_Debut) = dbo.FN_CRQ_DateNoTime(GETDATE())
			AND (LTRIM(RTRIM(ISNULL(vcTelephone, ''))) + ISNULL(vcExtension, '') = LTRIM(RTRIM(ISNULL(@OldOtherTel, '')))
				OR LTRIM(RTRIM(ISNULL(vcTelephone, ''))) + ISNULL(vcExtension, '') = LTRIM(RTRIM(ISNULL(@OldPager, '')))
				OR LTRIM(RTRIM(ISNULL(vcTelephone, ''))) + ISNULL(vcExtension, '') = LTRIM(RTRIM(ISNULL(@OldWattLine, ''))))
	
		-- Le nouveau téléphone est ajouté, s'il y en a un		
		IF LTRIM(RTRIM(ISNULL(@vcTelAutre, ''))) <> ''
			INSERT INTO tblGENE_Telephone(
				iID_Source,
				cType_Source,
				vcTelephone,
				vcExtension,
				iID_Type,
				dtDate_Debut,
				dtDate_Fin,
				bPublic,
				bInvalide,
				dtDate_Creation,
				vcLogin_Creation)
			VALUES (
				@SourceID,
				@AdrTypeID,
				SUBSTRING(LTRIM(@vcTelAutre), 1, 10),
				CASE WHEN LEN(LTRIM(RTRIM(@vcTelAutre))) > 10 THEN  SUBSTRING(LTRIM(@vcTelAutre), 11, LEN(LTRIM(RTRIM(@vcTelAutre))) - 10) ELSE NULL END,
				16,
				dbo.FN_CRQ_DateNoTime(@InForce),
				NULL,
				1,
				0,
				GETDATE(),
				@vcLogin_Creation)
		END

	INSERT INTO #DisableTrigger VALUES('TRG_GENE_Courriel_Historisation_D')	
	
	-- Adresse Courriel
	IF LTRIM(RTRIM(ISNULL(@EMail, ''))) <> LTRIM(RTRIM(ISNULL(@OldEMail, '')))
	BEGIN
		-- On inscrit une date de fin pour l'ancien Courriel si sa date de début est différente de celle du jour
		UPDATE tblGENE_Courriel
		SET dtDate_Fin = dbo.FN_CRQ_DateNoTime(GETDATE())	
		WHERE iID_Source = @SourceID
			AND iID_Type = 1
			AND dbo.FN_CRQ_DateNoTime(dtDate_Debut) <> dbo.FN_CRQ_DateNoTime(GETDATE())
			AND dtDate_Fin IS NULL
			AND LTRIM(RTRIM(ISNULL(vcCourriel, ''))) = LTRIM(RTRIM(ISNULL(@OldEmail, '')))

		-- Si la date de début de l'ancien Courriel est le même jour, on supprime ce dernier
		DELETE dbo.tblGENE_Courriel
		WHERE iID_Source = @SourceID
			AND iID_Type = 1
			AND dbo.FN_CRQ_DateNoTime(dtDate_Debut) = dbo.FN_CRQ_DateNoTime(GETDATE())
			AND LTRIM(RTRIM(ISNULL(vcCourriel, ''))) = LTRIM(RTRIM(ISNULL(@OldEmail, '')))
		
		-- Le nouveau Courriel est ajouté, s'il y en a un		
		IF LTRIM(RTRIM(ISNULL(@Email, ''))) <> ''
			INSERT INTO tblGENE_Courriel(
				iID_Source,
				cType_Source,
				vcCourriel,
				iID_Type,
				dtDate_Debut,
				dtDate_Fin,
				bPublic,
				bInvalide,
				dtDate_Creation,
				vcLogin_Creation)
			VALUES(
				@SourceID,
				@AdrTypeID,
				LTRIM(RTRIM(@EMail)),
				1,
				@InForce,
				NULL,
				1,
				0,
				GETDATE(),
				@vcLogin_Creation)
	END
	
	RETURN @AdrID
END


