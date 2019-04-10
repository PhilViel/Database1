/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	TT_UN_CESPOfConventions
Description         :	Gestion des enregistrements 100, 200 et 400 suite à la modification d'une convention, d'un 
								bénéficiaire ou d'un souscripteur
Valeurs de retours  :	>0  :	Tout à fonctionné
                     	<=0 :	Erreur SQL
Note                :	ADX0000831	IA	2006-03-21	Bruno Lapointe			Adaptation des conventions pour PCEE 4.3
						ADX0002077	BR	2006-09-05	Bruno Lapointe			BEC génère des commissions.
						ADX0001235	IA	2007-02-14	Alain Quirion			Utilisation de dtRegStartDate pour la date de début de régime
										2009-11-23	Jean-François Gauthier	Modification pour la détermination de la date effective (EffectDate)
																			Modification de la mise à jour de UN_CESP400 afin de ne pas modifier
																			les enregistrements dont la date de transaction est antérieure à la
																			date du changement de bénéficiaire
										2010-05-10	Pierre Paquet			Ajout du check de bCESPDemand pour ne pas supprimer les désactivations.
										2010-08-05	Pierre Paquet			J'ai mis en commentaire la section du update 400 car elle ne semblait pas bien fonctionner.
										2010-08-10	Pierre Paquet			Mise a jour de 400-24 plutôt que sa suppression.
										2010-08-24	Pierre Paquet			Il faut forcer l'exclusion du BEC lors de l'update.
										2010-09-01	Pierre Paquet			Gérer le changement de bénéficiaire lors de l'update des 400.
										2010-09-08	Pierre Paquet			Bogue du 1900-01-01, ne pas utiliser le FN_CRQ_DateNoTime
										2010-09-14	Pierre Paquet			Correction: Supprimer la trx si cela ne reflète pas la convention. BEC
										2015-02-02	Donald Huppé			faire left join sur mo_state pour les adresse hors Canada qui sont parfois null
										2015-02-13	Pierre-Luc Simard	Remplacer la validation du tiCESPState par l'éttat de la convention REE
										2015-02-13	Donald Huppé			Gestion du pays autre que CAN ou USA.
										2015-02-23	Pierre-Luc Simard	Ajout de la validation sur les NAS
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[TT_UN_CESPOfConventions] 
		(
			@ConnectID		INT,	-- Identifiant unique de la connection	
			@BeneficiaryID	INT,	-- ID du bénéficiaire (Traite toutes les conventions du bénéficiaire si <> 0)
			@SubscriberID	INT,	-- ID du souscripteur (Traite toutes les conventions du souscripteur si <> 0)
			@ConventionID	INT		-- ID de la convention (Traite la convention si <> 0)
		)
AS
BEGIN
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Start'

	DECLARE 
		@Result INTEGER

	SET @Result = 1

	DECLARE @tConvInForceDate TABLE (
		ConventionID INTEGER PRIMARY KEY)

	INSERT INTO @tConvInForceDate
		SELECT 
			C.ConventionID
		FROM dbo.Un_Convention C
		WHERE	C.ConventionID = @ConventionID
				OR C.BeneficiaryID = @BeneficiaryID
				OR C.SubscriberID = @SubscriberID
		GROUP BY C.ConventionID

	DECLARE @tCESPOfConventions TABLE (
		ConventionID INTEGER PRIMARY KEY,
		EffectDate DATETIME NOT NULL )

	INSERT INTO @tCESPOfConventions
		SELECT 
			C.ConventionID,
			EffectDate = -- Date d'entrée en vigueur de la convention pour le PCEE
				CASE 
					-- Avant le 1 janvier 2003 on envoi toujours la date d'entrée en vigueur de la convention
					-- 2009-11-23 : JFG : WHEN C.dtRegStartDate < '2003-01-01' THEN C.dtRegStartDate
					-- La date d'entrée en vigueur de la convention est la récente c'est donc elle qu'on envoit
					WHEN C.dtRegStartDate > B.BirthDate THEN C.dtRegStartDate
					-- La date de naissance du bénéficiaire est la plus récente c'est donc elle qu'on envoit
					ELSE B.BirthDate		
				END
		FROM @tConvInForceDate I 
		JOIN dbo.Un_Convention C ON I.ConventionID = C.ConventionID
		JOIN ( -- On s'assure que la convention a déjà été à l'état REEE
			SELECT DISTINCT
				CS.ConventionID
			FROM Un_ConventionConventionState CS
			WHERE CS.ConventionStateID = 'REE'
			) CSS ON CSS.ConventionID = C.ConventionID
		JOIN dbo.Mo_Human B ON B.HumanID = C.BeneficiaryID
		JOIN dbo.Mo_Human S ON S.HumanID = C.SubscriberID
		WHERE C.bSendToCESP <> 0 -- À envoyer au PCEE			
			AND C.dtRegStartDate IS NOT NULL	
			AND ISNULL(S.SocialNumber,'') <> ''
			AND ISNULL(B.SocialNumber,'') <> ''

		GROUP BY 
			C.ConventionID, 
			C.dtRegStartDate,
			B.BirthDate

	IF @Result = 1
	AND EXISTS (
		-- Vérifie si on doit supprimer les enregistrements 400 de demande de BEC non-expédiés (d'autres seront insérés pour les remplacer)
		SELECT iCESP400ID
		FROM Un_CESP400
		JOIN @tConvInForceDate C ON C.ConventionID = Un_CESP400.ConventionID
		WHERE Un_CESP400.iCESPSendFileID IS NULL
			AND Un_CESP400.tiCESP400TypeID = 24 -- BEC
		)
	BEGIN
		-- On supprime les demandes/désactivations de BEC si elle ne correspond pas à la convention.
		DELETE UN_CESP400
		FROM UN_CESP400
		JOIN @tConvInForceDate C ON C.ConventionID = Un_CESP400.ConventionID
		JOIN dbo.Un_Convention CONV ON CONV.ConventionID = UN_CESP400.ConventionID
		WHERE Un_CESP400.iCESPSendFileID IS NULL
			AND Un_CESP400.tiCESP400TypeID = 24 -- BEC
			AND UN_CESP400.bCESPDemand <>CONV.bCLBRequested 

		-- Mise à jour des enregistrements 400 de demande de BEC non-expédiés.
		UPDATE Un_CESP400
			SET 
				vcSubscriberSINorEN = SUBSTRING(S.SocialNumber,1,9),
				vcBeneficiarySIN = SUBSTRING(HB.SocialNumber,1,9),
				bCESPDemand = C.bCLBRequested,
				vcPCGSINorEN = B.vcPCGSINOrEN,
				vcPCGFirstName = B.vcPCGFirstName,
				vcPCGLastName = B.vcPCGLastName,
				tiPCGType = B.tiPCGType
			FROM Un_CESP400
			JOIN dbo.Un_Convention C ON C.ConventionID = Un_CESP400.ConventionID
			JOIN @tConvInForceDate CS ON CS.ConventionID = Un_CESP400.ConventionID
			JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
			JOIN dbo.Mo_Human HB ON HB.HumanID = C.BeneficiaryID
			JOIN dbo.Mo_Human S ON S.HumanID = C.SubscriberID
			INNER JOIN			-- 2010-09-01 Pierre Paquet
						(
							SELECT 
								ch2.iID_Convention, ch2.iID_Nouveau_Beneficiaire, ch1.dtDate_Changement_Beneficiaire
							FROM
								dbo.tblCONV_ChangementsBeneficiaire ch2
								INNER JOIN
									(
									SELECT
										tmp.iID_Convention, 
										dtDate_Changement_Beneficiaire = MAX(tmp.dtDate_Changement_Beneficiaire)
													
									FROM
										dbo.tblCONV_ChangementsBeneficiaire tmp
									GROUP BY 
										tmp.iID_Convention
									) ch1
										ON ch2.iID_Convention = ch1.iID_Convention AND ch2.dtDate_Changement_Beneficiaire = ch1.dtDate_Changement_Beneficiaire
						) cb

								ON cb.iID_Convention = c.ConventionID

					WHERE 
						Un_CESP400.iCESPSendFileID		IS NULL
						AND
						--dbo.FN_CRQ_DateNoTime(Un_CESP400.dtTransaction)	>  dbo.FN_CRQ_DateNoTime(cb.dtDate_Changement_Beneficiaire)					
						Un_CESP400.dtTransaction	>  cb.dtDate_Changement_Beneficiaire					
						AND UN_CESP400.tiCESP400TypeID = 24 

		IF @@ERROR <> 0
			SET @Result = -1

	END

	IF @Result = 1
	AND EXISTS (
		-- Vérifie si on doit supprimer les enregistrements 200 non-expédiés (d'autres seront insérés pour les remplacer)
		SELECT iCESP200ID
		FROM Un_CESP200
		JOIN @tConvInForceDate C ON C.ConventionID = Un_CESP200.ConventionID
		WHERE Un_CESP200.iCESPSendFileID IS NULL
		)
	BEGIN
		-- Supprime les enregistrements 200 non-expédiés (d'autres seront insérés pour les remplacer)
		DELETE Un_CESP200
		FROM Un_CESP200
		JOIN @tConvInForceDate C ON C.ConventionID = Un_CESP200.ConventionID
		WHERE Un_CESP200.iCESPSendFileID IS NULL

		IF @@ERROR <> 0
			SET @Result = -2
	END

	IF @Result = 1
	AND EXISTS (
		-- Vérifie si on doit supprimer les enregistrements 100 non-expédiés (d'autres seront insérés pour les remplacer)
		SELECT iCESP100ID
		FROM Un_CESP100
		JOIN @tConvInForceDate C ON C.ConventionID = Un_CESP100.ConventionID
		WHERE Un_CESP100.iCESPSendFileID IS NULL
		)
	BEGIN
		-- Supprime les enregistrements 100 non-expédiés (d'autres seront insérés pour les remplacer)
		DELETE Un_CESP100
		FROM Un_CESP100
		JOIN @tConvInForceDate C ON C.ConventionID = Un_CESP100.ConventionID
		WHERE Un_CESP100.iCESPSendFileID IS NULL

		IF @@ERROR <> 0
			SET @Result = -3
	END

	IF EXISTS (SELECT * FROM @tCESPOfConventions)
	BEGIN
		IF @Result = 1
		BEGIN
			-- Insert les enregistrements 200 (Bénéficiaire et souscripteur)
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
					CASE V.tiType
						WHEN 3 THEN 'BEN'
						WHEN 4 THEN 'SUB'
					END,
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
								WHEN RTRIM(A.CountryID) <> 'CAN' THEN isnull(A.Statename,'')
							ELSE ''
							END,
						vcAddress3 =
							CASE
								WHEN RTRIM(A.CountryID) NOT IN ('CAN','USA') THEN ISNULL(Co.CountryName,'')
							ELSE ''
							END,
						vcCity = ISNULL(A.City,''),
						vcStateCode = 
							CASE
								WHEN RTRIM(A.CountryID) = 'CAN' THEN UPPER(ST.StateCode)
							ELSE '' 
							END,
						CountryID = A.CountryID, -- Normalement, si différent de CAN ou USA, on devrait mettre OTH, mais la foreign key su mo_country ne fonctionnerait plus. À la place, On gère ça dans la création du fichier ASCII dans SL_UN_CESPSendFileASCII
						vcZipCode = --A.ZipCode,
							CASE
								WHEN RTRIM(A.CountryID) = 'CAN' THEN A.ZipCode
							ELSE ''
							END,
						cLang = H.LangID,
						vcTutorName =
							CASE 
								WHEN T.IsCompany = 0 THEN T.FirstName+' '+T.LastName
							ELSE T.LastName
							END,
						bIsCompany = H.IsCompany
					FROM dbo.Un_Beneficiary B
					JOIN dbo.Un_Convention C ON C.BeneficiaryID = B.BeneficiaryID
					JOIN @tCESPOfConventions CS ON CS.ConventionID = C.ConventionID
					JOIN Un_Plan P ON P.PlanID = C.PlanID
					JOIN dbo.Mo_Human H ON H.HumanID = B.BeneficiaryID
					JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
					JOIN Mo_Country Co ON Co.CountryID = A.CountryID
					left JOIN Mo_State ST ON ST.StateName = A.StateName
					JOIN dbo.Mo_Human T ON T.HumanID = B.iTutorID
					-----
					UNION
					-----
					SELECT
						C.ConventionID,
						HumanID = S.SubscriberID,
						C.tiRelationshipTypeID,
						tiType = 4,
						dtTransaction = CS.EffectDate,
						iPlanGovRegNumber = P.PlanGovernmentRegNo,
						ConventionNo = C.ConventionNo,
						vcSINorEN = H.SocialNumber,
						vcFirstName = ISNULL(H.FirstName,''),
						vcLastName = H.LastName,
						dtBirthdate = H.BirthDate,
						cSex = H.SexID,
						vcAddress1 = A.Address,
						vcAddress2 = 
							CASE
								WHEN RTRIM(A.CountryID) <> 'CAN' THEN isnull(A.Statename,'')
							ELSE ''
							END,
						vcAddress3 =
							CASE
								WHEN RTRIM(A.CountryID) NOT IN ('CAN','USA') THEN ISNULL(Co.CountryName,'')
							ELSE ''
							END,
						vcCity = ISNULL(A.City,''),
						vcStateCode = 
							CASE
								WHEN RTRIM(A.CountryID) = 'CAN' THEN UPPER(ST.StateCode)
							ELSE '' 
							END,
						CountryID = A.CountryID, -- Normalement, si différent de CAN ou USA, on devrait mettre OTH, mais la foreign key su mo_country ne fonctionnerait plus. À la place, On gère ça dans la création du fichier ASCII dans SL_UN_CESPSendFileASCII
						vcZipCode = --A.ZipCode,
							CASE
								WHEN RTRIM(A.CountryID) = 'CAN' THEN A.ZipCode
							ELSE ''
							END,
						cLang = H.LangID,
						vcTutorName = NULL,
						bIsCompany = H.IsCompany
					FROM dbo.Un_Beneficiary B
					JOIN dbo.Un_Convention C ON C.BeneficiaryID = B.BeneficiaryID
					JOIN @tCESPOfConventions CS ON CS.ConventionID = C.ConventionID
					JOIN Un_Plan P ON P.PlanID = C.PlanID
					JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
					JOIN dbo.Mo_Human H ON H.HumanID = S.SubscriberID
					JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
					JOIN Mo_Country Co ON Co.CountryID = A.CountryID
					left JOIN Mo_State ST ON ST.StateName = A.StateName
					) V
				LEFT JOIN (
					SELECT 
						G2.HumanID, 
						G2.ConventionID,
						G2.tiType,
						iCESPSendFileID = MAX(G2.iCESPSendFileID)
					FROM Un_CESP200 G2
					JOIN @tCESPOfConventions CS ON CS.ConventionID = G2.ConventionID
					GROUP BY
						G2.HumanID, 
						G2.ConventionID,
						G2.tiType
					) M ON M.HumanID = V.HumanID AND M.ConventionID = V.ConventionID AND M.tiType = V.tiType
				LEFT JOIN Un_CESP200 G2 ON G2.HumanID = M.HumanID AND G2.ConventionID = M.ConventionID AND G2.iCESPSendFileID = M.iCESPSendFileID AND G2.tiType = M.tiType
				-- S'assure que les informations ne sont pas les mêmes que les dernières expédiées
				WHERE V.tiType <> G2.tiType
					OR	V.dtTransaction <> G2.dtTransaction
					OR	V.iPlanGovRegNumber <> G2.iPlanGovRegNumber
					OR	V.ConventionNo <> G2.ConventionNo
					OR	V.vcSINorEN <> G2.vcSINorEN
					OR	V.vcFirstName <> G2.vcFirstName
					OR	V.vcLastName <> G2.vcLastName
					OR	V.dtBirthdate <> G2.dtBirthdate
					OR	V.cSex <> G2.cSex
					OR	V.vcAddress1 <> G2.vcAddress1
					OR	V.vcAddress2 <> G2.vcAddress2
					OR	V.vcAddress3 <> G2.vcAddress3
					OR	V.vcCity <> G2.vcCity
					OR	V.vcStateCode <> G2.vcStateCode
					OR	V.CountryID <> G2.CountryID
					OR	V.vcZipCode <> G2.vcZipCode
					OR	V.cLang <> G2.cLang
					OR	V.vcTutorName <> G2.vcTutorName
					OR V.bIsCompany <> G2.bIsCompany
					OR V.tiRelationshipTypeID <> G2.tiRelationshipTypeID
					OR G2.iCESP200ID IS NULL

			IF @@ERROR <> 0
				SET @Result = -4
		END

		IF @Result = 1
		BEGIN
			-- Inscrit le vcTransID avec le ID Ex: BEN + <iCESP200ID>.
			UPDATE Un_CESP200
			SET vcTransID = vcTransID+CAST(iCESP200ID AS VARCHAR(12))
			WHERE vcTransID IN ('BEN','SUB')

			IF @@ERROR <> 0
				SET @Result = -5
		END
		-----------------------------------------------
		-- Fin de la gestion des enregistrements 200 --
		-----------------------------------------------

		-------------------------------------------------
		-- Début de la gestion des enregistrements 100 --
		-------------------------------------------------
		IF @Result = 1
		BEGIN
			-- Insertion d'enregistrements 100 pour les conventions
			INSERT INTO Un_CESP100 (
					ConventionID,
					vcTransID,
					dtTransaction,
					iPlanGovRegNumber,
					ConventionNo )
				SELECT
					C.ConventionID,
					'CON',
					CS.EffectDate,
					P.PlanGovernmentRegNo,
					C.ConventionNo
				FROM @tCESPOfConventions CS
				JOIN dbo.Un_Convention C ON CS.ConventionID = C.ConventionID
				JOIN Un_Plan P ON P.PlanID = C.PlanID
				LEFT JOIN (
					SELECT 
						G1.ConventionID,
						iCESPSendFileID = MAX(G1.iCESPSendFileID)
					FROM Un_CESP100 G1
					JOIN @tCESPOfConventions CS ON CS.ConventionID = G1.ConventionID
					GROUP BY
						G1.ConventionID
					) M ON M.ConventionID = C.ConventionID
				LEFT JOIN Un_CESP100 G1 ON G1.ConventionID = M.ConventionID AND G1.iCESPSendFileID = M.iCESPSendFileID
				-- S'assure que les informations ne sont pas les mêmes que les dernières expédiées
				WHERE CS.EffectDate <> G1.dtTransaction
					OR	P.PlanGovernmentRegNo <> G1.iPlanGovRegNumber
					OR	C.ConventionNo <> G1.ConventionNo
					OR G1.iCESP100ID IS NULL

				IF @@ERROR <> 0
					SET @Result = -6
		END

		IF @Result = 1
		BEGIN
			-- Inscrit le vcTransID avec le ID CON + <iCESP100ID>.
			UPDATE Un_CESP100
			SET vcTransID = vcTransID+CAST(iCESP100ID AS VARCHAR(12))
			WHERE vcTransID = 'CON' 

			IF @@ERROR <> 0
				SET @Result = -7
		END
		-----------------------------------------------
		-- Fin de la gestion des enregistrements 100 --
		-----------------------------------------------

		-------------------------------------------------
		-- Début de la gestion des enregistrements 400 --
		-------------------------------------------------
		IF @Result = 1
		BEGIN
			-- Met … jour l'informations des enregistrements 400 qui n'ont pas ‚t‚ exp‚di‚s. Cela exclu les demande de BEC car 
			-- les enregistrements 400 de BEC non-exp‚di‚s ont ‚t‚ pr‚alablement supprim‚s.
			UPDATE Un_CESP400
			SET 
				vcSubscriberSINorEN = SUBSTRING(S.SocialNumber,1,9),
				vcBeneficiarySIN = SUBSTRING(HB.SocialNumber,1,9),
				bCESPDemand = 
					CASE 
						WHEN Un_CESP400.tiCESP400TypeID = 11 THEN C.bCESGRequested
					ELSE 1
					END,
				vcPCGSINorEN =
					CASE 
						WHEN ( C.bACESGRequested <> 0 AND Un_CESP400.tiCESP400TypeID = 11 ) THEN B.vcPCGSINOrEN
					ELSE NULL
					END,
				vcPCGFirstName =
					CASE 
						WHEN ( C.bACESGRequested <> 0 AND Un_CESP400.tiCESP400TypeID = 11 ) THEN B.vcPCGFirstName
					ELSE NULL
					END,
				vcPCGLastName =
					CASE 
						WHEN ( C.bACESGRequested <> 0 AND Un_CESP400.tiCESP400TypeID = 11 ) THEN B.vcPCGLastName
					ELSE NULL
					END,
				tiPCGType =
					CASE 
						WHEN ( C.bACESGRequested <> 0 AND Un_CESP400.tiCESP400TypeID = 11 ) THEN B.tiPCGType
					ELSE NULL
					END
			FROM Un_CESP400
			JOIN dbo.Un_Convention C ON C.ConventionID = Un_CESP400.ConventionID
			JOIN @tCESPOfConventions CS ON CS.ConventionID = Un_CESP400.ConventionID
			JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
			JOIN dbo.Mo_Human HB ON HB.HumanID = C.BeneficiaryID
			JOIN dbo.Mo_Human S ON S.HumanID = C.SubscriberID
			INNER JOIN			-- 2010-09-01 Pierre Paquet
			(
				SELECT 
					ch2.iID_Convention, ch2.iID_Nouveau_Beneficiaire, ch2.dtDate_Changement_Beneficiaire
				FROM
					dbo.tblCONV_ChangementsBeneficiaire ch2
					INNER JOIN
						(
						SELECT
							tmp.iID_Convention, 
							dtDate_Changement_Beneficiaire = MAX(tmp.dtDate_Changement_Beneficiaire)
						FROM
							dbo.tblCONV_ChangementsBeneficiaire tmp
						GROUP BY 
							tmp.iID_Convention
						) ch1
							ON ch2.iID_Convention = ch1.iID_Convention 
			) cb
					ON cb.iID_Convention = c.ConventionID
			WHERE 
				Un_CESP400.iCESPSendFileID		IS NULL
				AND
				--dbo.FN_CRQ_DateNoTime(Un_CESP400.dtTransaction)	>  dbo.FN_CRQ_DateNoTime(cb.dtDate_Changement_Beneficiaire)					
				Un_CESP400.dtTransaction	>  cb.dtDate_Changement_Beneficiaire
				AND
				Un_CESP400.tiCESP400TypeID <> 24 -- Exclure les types 24 (BEC)

			IF @@ERROR <> 0
				SET @Result = -8
		END
		-----------------------------------------------
		-- Fin de la gestion des enregistrements 400 --
		-----------------------------------------------
	END

	EXEC dbo.TT_PrintDebugMsg @@PROCID, 'End'
		
	RETURN @Result
END


