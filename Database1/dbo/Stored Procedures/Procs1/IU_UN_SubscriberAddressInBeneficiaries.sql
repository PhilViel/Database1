/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_SubscriberAddressInBeneficiaries
Description         :	Sauvegarde l'adresse du souscripteur dans les bénéficiaires
Valeurs de retours  :	Dataset de données
Note                :	
	ADX0000323	IA	2004-09-29	Bruno Lapointe 	Création (10.02.02)
	ADX0000590	IA	2004-11-19	Bruno Lapointe	Remplacer IMo_Adr par SP_IU_CRQ_Adr
	ADX0001331	IA	2007-04-17	Bruno Lapointe	Gestion des changements d'adresse anticipé sur souscripteur qui 
																		s'applique au bénéficiaire.
	ADX0003102	UR	2007-12-06	Bruno Lapointe		Envoi des 200 au PCEE suite au changement d'adresse.
					2011-04-19	Donald Huppé			Correction de la mise-à-jour du AdrID de l'humain bénéficiaire.
																	Il était après le curseur alors tout les bénéficiaires avaient le même adrid (donc le mauvais sourceID)
					2014-07-10	Maxime Martel		GLPI 11921 (insertion dans la table d'historique l'ancienne adresse)
					2014-07-10	Pierre-Luc Simard	Retrait de la gestion des 200, remplacé temporairement par script mensuel
					2015-06-30  Steve Picard		L'historisation se fait par les triggers maintenant
												
	exec IU_UN_SubscriberAddressInBeneficiaries 705718,150075,0,'285784,285785,285786,'
	
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_SubscriberAddressInBeneficiaries] (
	@ConnectID INTEGER, -- ID unique de connexion de l’usager
	@SubscriberID INTEGER, -- ID Unique du souscripteur
	@AdrID INTEGER, -- ID de l’adresse du souscripteur à appliquer sur les bénéficiaires (0 lors de l’édition d’un souscripteur)
	@BeneficiaryIDs VARCHAR(8000)) -- Liste de IDs de bénéficiaires
AS
BEGIN
	-- Valeurs de retour :
	-- > 0  : Tout à fonctionné
	-- <= 0 : Erreurs ->
	-- 	-1 : le souscripteur n'existe pas dans la base de données
	-- 	-2 : le souscipteur n'a pas d'adresse
	-- 	-3 : Erreur à la sauvegarde de l'adresse
	-- 	-4 : Erreur à la mise à jour du AdrID de l'humain (bénéficiaire)
	-- 	Autres : Erreurs non répertoriés
	DECLARE 
		@Result INTEGER,
		@bAnticiped BIT

	SET @Result = @SubscriberID

	-----------------
	BEGIN TRANSACTION
	-----------------

	-- Vérifie que le souscripteur existe
	IF NOT EXISTS (
			SELECT SubscriberID
			FROM dbo.Un_Subscriber 
			WHERE SubscriberID = @SubscriberID)
		SET @Result = -1

	-- Vérifie que le souscripteur a une adresse
	IF @Result > 0 AND
		EXISTS (
			SELECT S.SubscriberID
			FROM dbo.Un_Subscriber S
			JOIN dbo.Mo_Human H ON H.HumanID = S.SubscriberID
			LEFT JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
			WHERE S.SubscriberID = @SubscriberID
			  AND A.AdrID IS NULL)
			
		SET @Result = -2
		
	IF ISNULL(@AdrID,0) <= 0
	BEGIN
		SELECT
			@AdrID = AdrID,
			@bAnticiped = 0 -- Pas un changement anticipé donc est l'adresse courante du souscripteur
		FROM dbo.Mo_Human
		WHERE HumanID = @SubscriberID
	END
	ELSE
		SET @bAnticiped = 1 -- Changement d'adresse anticipé, ce nest pas l'adresse courante du souscripteur

	IF @Result > 0
	BEGIN
		-- Déclaratrion des variables
		DECLARE
			@iAdrID MoIDOption,
			@InForce MoDate,
			@AdrTypeID MoAdrType,
			@BeneficiaryID MoID,
			@Address MoAdress,
			@City MoCity,
			@StateName MoDescOption,
			@CountryID MoCountry,
			@ZipCode MoZipCode,
			@Phone1 MoPhoneExt,
			@Phone2 MoPhoneExt,
			@Fax MoPhone,
			@Mobile MoPhone,
			@WattLine MoPhoneExt,
			@OtherTel MoPhoneExt,
			@Pager MoPhone,
			@EMail MoEmail		

		-- Va chercher l'adresse du souscripteur
		SELECT 
			@InForce = InForce,
			@AdrTypeID = AdrTypeID,
			@Address = Address,
			@City = City,
			@StateName = StateName,
			@CountryID = CountryID,
			@ZipCode = ZipCode,
			@Phone1 = Phone1
		FROM dbo.Mo_Adr 
		WHERE AdrID = @AdrID

		-- Création d'une table temporaire des bénéficiaires dont l'adresse doit être modifiée.
		DECLARE @tBeneficiaries TABLE (
			BeneficiaryID INT PRIMARY KEY )

		INSERT INTO @tBeneficiaries
			SELECT Val
			FROM dbo.FN_CRQ_IntegerTable(@BeneficiaryIDs)

		-- Déclaration d'un curseur pour boucler sur les bénéficiaires afin de sauvegarder la modification de l'adresse
		DECLARE BeneficiaryIDs CURSOR FOR
			SELECT 
				H.AdrID,
				B.BeneficiaryID,
				Phone2 = ISNULL(A.Phone2,''),
				Fax = ISNULL(A.Fax,''),
				Mobile = ISNULL(A.Mobile,''),
				WattLine = ISNULL(A.WattLine,''),
				OtherTel = ISNULL(A.OtherTel,''),
				Pager = ISNULL(A.Pager,''),
				EMail = ISNULL(A.EMail,'')
			FROM @tBeneficiaries B
			JOIN dbo.Mo_Human H ON H.HumanID = B.BeneficiaryID
			LEFT JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID

		OPEN BeneficiaryIDs
	
		FETCH NEXT FROM BeneficiaryIDs
		INTO
			@iAdrID,
			@BeneficiaryID,
			@Phone2,
			@Fax,
			@Mobile,
			@WattLine,
			@OtherTel,
			@Pager,
			@EMail

		WHILE @@FETCH_STATUS = 0 AND @Result > 0
		BEGIN
			-- Création ou modification de l'adresse du bénéficiaire
			EXECUTE @iAdrID = SP_IU_CRQ_Adr
				@ConnectID,
				@iAdrID,
				@InForce,
				@AdrTypeID,
				@BeneficiaryID,
				@Address,
				@City,
				@StateName,
				@CountryID,
				@ZipCode,
				@Phone1,
				@Phone2,
				@Fax,
				@Mobile,
				@WattLine,
				@OtherTel,
				@Pager,
				@EMail

			-- Erreur à la sauvegarde de l'adresse
			IF @iAdrID <= 0
				SET @Result = -3

			-- Mets à jour le AdrID de l'humain (bénéficiaire)
			IF @Result > 0 AND @bAnticiped = 0
			BEGIN
				UPDATE dbo.Mo_Human 
				SET
					AdrID = @iAdrID
				WHERE HumanID = @BeneficiaryID

				IF @@ERROR <> 0 
					SET @Result = -4
			END
			
			/***********************************************/
			/*					GLPI 11921				   */
			/***********************************************/
			
			-- Supprimer les autres adresses de la même journée
			DELETE tblGENE_Adresse
			WHERE iID_Source = @BeneficiaryID
				AND iID_Type = 1
				AND dtDate_Debut = dbo.FN_CRQ_DateNoTime(GETDATE())
				AND iID_Adresse <> @iAdrID
			
			--	Déplacer l'ancienne adresse dans la table historique si celle-ci n'a pas été supprimée 
			--IF EXISTS (SELECT 1 FROM tblGENE_Adresse A WHERE A.iID_Adresse = @Old_AdrID) 
			--BEGIN
				---- On insère l'ancienne adresse dans la table des adresses historiques
				--INSERT INTO tblGENE_AdresseHistorique (
				--	iID_Source,
				--	cType_Source,
				--	iID_Type,
				--	dtDate_Debut,
				--	dtDate_Fin,
				--	bInvalide,
				--	dtDate_Creation,
				--	vcLogin_Creation,
				--	vcNumero_Civique,
				--	vcNom_Rue,
				--	vcUnite,
				--	vcCodePostal,
				--	vcBoite,
				--	iID_TypeBoite,
				--	iID_Ville,
				--	vcVille,
				--	iID_Province,
				--	vcProvince,
				--	cID_Pays,
				--	vcPays,
				--	bNouveau_Format,
				--	bResidenceFaitQuebec,
				--	bResidenceFaitCanada,
				--	vcInternationale1,
				--	vcInternationale2,
				--	vcInternationale3)
				--SELECT     
				--	iID_Source,
				--	cType_Source,
				--	iID_Type,
				--	dtDate_Debut,
				--	dbo.FN_CRQ_DateNoTime(GETDATE()), 
				--	bInvalide,
				--	dtDate_Creation,
				--	vcLogin_Creation,
				--	vcNumero_Civique,
				--	vcNom_Rue,
				--	vcUnite,
				--	vcCodePostal,
				--	vcBoite,
				--	iID_TypeBoite,
				--	iID_Ville,
				--	vcVille,
				--	iID_Province,
				--	vcProvince,
				--	cID_Pays,
				--	vcPays,
				--	bNouveau_Format,
				--	bResidenceFaitQuebec,
				--	bResidenceFaitCanada,
				--	vcInternationale1,
				--	vcInternationale2,
				--	vcInternationale3
				--FROM tblGENE_Adresse A
				----WHERE A.iID_Adresse = @Old_AdrID
				--WHERE iID_Source = @BeneficiaryID
				--	AND iID_Type = 1
				--	AND dtDate_Debut < dbo.FN_CRQ_DateNoTime(GETDATE())
				--	AND iID_Adresse <> @iAdrID
				
				-- On supprime l'ancienne adresse de la table des adresses courantes
				DELETE FROM tblGENE_Adresse 
				--WHERE iID_Adresse = @Old_AdrID
				WHERE iID_Source = @BeneficiaryID
					AND iID_Type = 1
					AND dtDate_Debut < dbo.FN_CRQ_DateNoTime(GETDATE())
					AND iID_Adresse <> @iAdrID
			
			/*************************************************/
			
			FETCH NEXT FROM BeneficiaryIDs
			INTO
				@iAdrID,
				@BeneficiaryID,
				@Phone2,
				@Fax,
				@Mobile,
				@WattLine,
				@OtherTel,
				@Pager,
				@EMail
		END

		-- Detruit le curseur
		CLOSE BeneficiaryIDs
		DEALLOCATE BeneficiaryIDs
	END

/* -- 2011-04-19
	-- Mets à jour le AdrID de l'humain (bénéficiaire)
	IF @Result > 0 AND @bAnticiped = 0
	BEGIN
		UPDATE dbo.Mo_Human 
		SET
			AdrID = @iAdrID
		WHERE HumanID IN (SELECT BeneficiaryID FROM @tBeneficiaries) 

		IF @@ERROR <> 0 
			SET @Result = -4
	END
*/
/*
	IF @Result > 0 AND @bAnticiped = 0
	BEGIN
		-- Supprime les enregistrements 200 non envoyé lié au bénéficiaire dont 
		-- l'adresse a changée. Ils seront recréés avec les données à jour.
		DELETE 
		FROM Un_CESP200
		WHERE HumanID IN (SELECT BeneficiaryID FROM @tBeneficiaries) -- Adresses changées
			AND iCESPSendFileID IS NULL
			
		IF @@ERROR <> 0 
			SET @Result = -5
	END

	IF @Result > 0 AND @bAnticiped = 0
	BEGIN
		-- Table temporaire des conventions et de leurs dates d'entrées en vigueur 
		-- pour le PCEE
		DECLARE @tCESPOfConventions TABLE (
			ConventionID INTEGER PRIMARY KEY,
			EffectDate DATETIME NOT NULL )

		INSERT INTO @tCESPOfConventions
			SELECT 
				C.ConventionID,
				EffectDate = -- Date d'entrée en vigueur de la convention pour le PCEE
					CASE 
						-- Avant le 1 janvier 2003 on envoi toujours la date d'entrée en vigueur de la convention
						WHEN C.dtRegStartDate < '2003-01-01' THEN C.dtRegStartDate
						-- La date d'entrée en vigueur de la convention est la récente c'est donc elle qu'on envoit
						WHEN C.dtRegStartDate > B.BirthDate THEN C.dtRegStartDate
						-- La date de naissance du bénéficiaire est la plus récente c'est donc elle qu'on envoit
						ELSE B.BirthDate		
					END
			FROM @tBeneficiaries Bn
			JOIN dbo.Un_Convention C ON Bn.BeneficiaryID = C.BeneficiaryID
			JOIN dbo.Mo_Human B ON B.HumanID = C.BeneficiaryID
			JOIN dbo.Un_Convention I ON I.ConventionID = C.ConventionID
			WHERE	C.tiCESPState > 0 -- Pré-validation minimums passe sur la convention
				AND C.bSendToCESP <> 0 -- À envoyer au PCEE			
				AND C.dtRegStartDate IS NOT NULL	-- 
				AND C.ConventionID NOT IN ( -- Conventions fermées
						SELECT T.ConventionID
						FROM (-- Retourne la plus grande date de début d'un état par convention
							SELECT 
								S.ConventionID,
								MaxDate = MAX(S.StartDate)
							FROM Un_ConventionConventionState S
							JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
							GROUP BY S.ConventionID
							) T
						JOIN Un_ConventionConventionState CCS ON T.ConventionID = CCS.ConventionID AND T.MaxDate = CCS.StartDate -- Retrouve l'état correspondant à la plus grande date par convention
						WHERE CCS.ConventionStateID = 'FRM'
						)
			GROUP BY 
				C.ConventionID, 
				C.dtRegStartDate,
				B.BirthDate

		IF @@ERROR <> 0 
			SET @Result = -6
	END

	IF @Result > 0 AND @bAnticiped = 0
	BEGIN
		-- Crées les 200 avec les adresses à jour. 
		INSERT INTO Un_CESP200 (
				ConventionID,
				HumanID,
				tiRelationshipTypeID,
				vcTransID,
				tiType,
				dtTransaction,
				iPlanGovRegNumber,
				ConventionNo,
				vcSINorEN,
				vcFirstName,
				vcLastName,
				dtBirthdate,
				cSex,
				vcAddress1,
				vcAddress2,
				vcAddress3,
				vcCity,
				vcStateCode,
				CountryID,
				vcZipCode,
				cLang,
				vcTutorName,
				bIsCompany )
			SELECT
				V.ConventionID,
				V.HumanID,
				V.tiRelationshipTypeID,		
				'BEN',
				V.tiType,
				V.dtTransaction,
				V.iPlanGovRegNumber,
				V.ConventionNo,
				V.vcSINorEN,
				V.vcFirstName,
				V.vcLastName,
				V.dtBirthdate,
				V.cSex,
				V.vcAddress1,
				V.vcAddress2,
				V.vcAddress3,
				V.vcCity,
				V.vcStateCode,
				V.CountryID,
				V.vcZipCode,
				V.cLang,
				V.vcTutorName,
				V.bIsCompany
			FROM (
				SELECT
					C.ConventionID,
					HumanID = B.BeneficiaryID,
					tiRelationshipTypeID = NULL,
					tiType = 3,
					dtTransaction = CS.EffectDate,
					iPlanGovRegNumber = P.PlanGovernmentRegNo,
					ConventionNo = C.ConventionNo,
					vcSINorEN = H.SocialNumber,
					vcFirstName = H.FirstName,
					vcLastName = H.LastName,
					dtBirthdate = H.BirthDate,
					cSex = H.SexID,
					vcAddress1 = A.Address,
					vcAddress2 = 
						CASE
							WHEN RTRIM(A.CountryID) <> 'CAN' THEN A.Statename
						ELSE ''
						END,
					vcAddress3 =
						CASE
							WHEN RTRIM(A.CountryID) NOT IN ('CAN','USA') THEN ISNULL(Co.CountryName,'')
						ELSE ''
						END,
					vcCity = A.City,
					vcStateCode = 
						CASE
							WHEN RTRIM(A.CountryID) = 'CAN' THEN UPPER(ST.StateCode)
						ELSE '' 
						END,
					CountryID = A.CountryID,
					vcZipCode = A.ZipCode,
					cLang = H.LangID,
					vcTutorName =
						CASE 
							WHEN T.IsCompany = 0 THEN T.FirstName+' '+T.LastName
						ELSE T.LastName
						END,
					bIsCompany = H.IsCompany
				FROM @tBeneficiaries HP
				JOIN dbo.Un_Beneficiary B ON HP.BeneficiaryID = B.BeneficiaryID
				JOIN dbo.Un_Convention C ON C.BeneficiaryID = B.BeneficiaryID
				JOIN @tCESPOfConventions CS ON CS.ConventionID = C.ConventionID
				JOIN Un_Plan P ON P.PlanID = C.PlanID
				JOIN dbo.Mo_Human H ON H.HumanID = B.BeneficiaryID
				JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
				JOIN Mo_Country Co ON Co.CountryID = A.CountryID
				JOIN Mo_State ST ON ST.StateName = A.StateName
				JOIN dbo.Mo_Human T ON T.HumanID = B.iTutorID
				) V
			LEFT JOIN (
				SELECT 
					G2.HumanID, 
					G2.ConventionID,
					G2.tiType,
					iCESPSendFileID = MAX(ISNULL(G2.iCESPSendFileID,999))
				FROM Un_CESP200 G2
				JOIN @tCESPOfConventions CS ON CS.ConventionID = G2.ConventionID
				GROUP BY
					G2.HumanID, 
					G2.ConventionID,
					G2.tiType
				) M ON M.HumanID = V.HumanID AND M.ConventionID = V.ConventionID AND M.tiType = V.tiType
			LEFT JOIN Un_CESP200 G2 ON G2.HumanID = M.HumanID 
											AND G2.ConventionID = M.ConventionID 
											AND ISNULL(G2.iCESPSendFileID,999) = ISNULL(M.iCESPSendFileID,999) 
											AND G2.tiType = M.tiType
			-- S'assure que les informations ne sont pas les mêmes que les dernières expédiées
			WHERE G2.iCESP200ID IS NULL
				OR V.dtTransaction <> G2.dtTransaction
				OR	V.iPlanGovRegNumber <> G2.iPlanGovRegNumber
				OR V.ConventionNo <> G2.ConventionNo
				OR V.vcSINorEN <> G2.vcSINorEN
				OR V.vcFirstName <> G2.vcFirstName
				OR V.vcLastName <> G2.vcLastName
				OR V.dtBirthdate <> G2.dtBirthdate
				OR V.cSex <> G2.cSex
				OR V.vcAddress1 <> G2.vcAddress1
				OR V.vcAddress2 <> G2.vcAddress2
				OR V.vcAddress3 <> G2.vcAddress3
				OR V.vcCity <> G2.vcCity
				OR V.vcStateCode <> G2.vcStateCode
				OR V.CountryID <> G2.CountryID
				OR V.vcZipCode <> G2.vcZipCode
				OR V.cLang <> G2.cLang
				OR V.vcTutorName <> G2.vcTutorName
				OR V.bIsCompany <> G2.bIsCompany
				OR V.tiRelationshipTypeID <> G2.tiRelationshipTypeID

		IF @@ERROR <> 0 
			SET @Result = -7
	END

	IF @Result > 0 AND @bAnticiped = 0
	BEGIN
		-- Inscrit le vcTransID avec le ID Ex: BEN + <iCESP200ID>.
		UPDATE Un_CESP200
		SET vcTransID = vcTransID+CAST(iCESP200ID AS VARCHAR(12))
		WHERE vcTransID IN ('BEN','SUB')

		IF @@ERROR <> 0 
			SET @Result = -8
	END
*/
	IF @Result > 0
		------------------
		COMMIT TRANSACTION
		------------------
	ELSE
		--------------------
		ROLLBACK TRANSACTION
		--------------------

	RETURN @Result
END


