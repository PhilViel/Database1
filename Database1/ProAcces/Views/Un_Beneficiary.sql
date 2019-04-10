CREATE VIEW [ProAcces].[Un_Beneficiary] AS
	SELECT BeneficiaryID, iTutorID, bTutorIsSubscriber, vcPCGSINorEN, vcPCGFirstName, vcPCGLastName, tiPCGType, bPCGIsSubscriber, ResponsableNEQ, tiCESPState, bReleve_Papier, bDevancement_AdmissibilitePAE
	FROM dbo.Un_Beneficiary
GO
CREATE TRIGGER [ProAcces].[TR_Un_Beneficiary_Del] ON [ProAcces].[Un_Beneficiary]
	   INSTEAD OF DELETE
AS BEGIN
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Start'
	-- *** AVERTISSEMENT *** Ce script doit toujours figurer en tête de trigger

	-- Si la table #DisableTrigger est présente, il se pourrait que le trigger
	-- ne soit pas à exécuter
	IF object_id('tempdb..#DisableTrigger') is null 
		CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))
	ELSE BEGIN
		-- Le trigger doit être retrouvé dans la table pour être ignoré
		IF EXISTS (SELECT 1 FROM #DisableTrigger WHERE OBJECT_NAME(@@PROCID) like vcTriggerName)
		BEGIN
			-- Ne pas faire le trigger
			EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Trigger Ignored'
			RETURN
		END
	END

	-- *** FIN AVERTISSEMENT *** 

	DECLARE @Now datetime = GetDate()
		,	@RecSep CHAR(1) = CHAR(30)
		,	@CrLf CHAR(2) = CHAR(13) + CHAR(10)
		,	@ActionID int = (SELECT LogActionID FROM CRQ_LogAction WHERE LogActionShortName = 'D')
		,	@iID_Utilisateur INT = (SELECT iID_Utilisateur_Systeme FROM dbo.Un_Def)

	;WITH CTE_Human (HumanID, FirstName, LastName, SexID, LangID, SocialNumber, PaysID_Origine, BirthDate, DeathDate) 
	as (
		SELECT	HumanID, FirstName, LastName, SexID, LangID, SocialNumber, cID_Pays_Origine, BirthDate, DeathDate
		  FROM deleted D
				JOIN ProAcces.Mo_Human H ON H.HumanID = D.BeneficiaryID
	),
	CTE_Adresse (SourceID, AdresseID, City, StateName, CountryID, CountryName, ZipCode, Nouveau_Format, Adresse)
	as (
		SELECT HumanID, iID_Adresse, vcVille, vcProvince, cID_Pays, C.CountryName, vcCodePostal, bNouveau_Format, 
			   Adresse =	CASE 
								WHEN A.cID_Pays <> 'CAN' AND A.bNouveau_Format = 1 
									THEN RTrim(RTrim(IsNull(A.vcInternationale1 , '') + SPACE(1) + IsNull(A.vcInternationale2, '')) + SPACE(1) + IsNull(A.vcInternationale3, ''))
								ELSE 
									CASE WHEN ISNULL(A.vcUnite, '') <> '' THEN A.vcUnite + '-' ELSE '' END + 
									CASE WHEN ISNULL(A.vcNumero_Civique, '') <> '' THEN A.vcNumero_Civique + '' ELSE '' END + 
									CASE WHEN ISNULL(A.vcNom_Rue, '') <> '' THEN SPACE(1) + A.vcNom_Rue ELSE '' END + 
									CASE WHEN ISNULL(A.vcBoite , '') <> '' THEN SPACE(1) + 
										CASE WHEN A.iID_TypeBoite = 1 THEN 'CP'
												WHEN A.iID_TypeBoite = 3 THEN 'RR'
										END + SPACE(1) + A.vcBoite 
									ELSE '' END
							END
		  FROM CTE_Human H INNER JOIN dbo.tblGENE_Adresse A ON A.iID_Source = H.HumanID
						   LEFT JOIN dbo.Mo_Country C ON C.CountryID = A.cID_Pays
	),
	CTE_Phone (SourceID, AdresseID, Phone1, Phone2, Fax, Mobile, OtherTel, EMail)
	as (
		SELECT SourceID, AdresseID,
		       Phone1 = dbo.fnGENE_TelephoneEnDate (SourceID, 1, NULL, 0, 0),
			   Phone2 = dbo.fnGENE_TelephoneEnDate (SourceID, 4, NULL, 0, 0),
			   Fax = dbo.fnGENE_TelephoneEnDate (SourceID, 8, NULL, 0, 0),
			   Mobile = dbo.fnGENE_TelephoneEnDate (SourceID, 2, NULL, 0, 0),
			   OtherTel = dbo.fnGENE_TelephoneEnDate (SourceID, 16, NULL, 0, 0),
			   EMail = dbo.fnGENE_CourrielEnDate (SourceID, 1, NULL, 0)
		  FROM CTE_Adresse
	)
	INSERT INTO CRQ_Log (ConnectID, LogTableName, LogCodeID, LogTime, LogActionID, LogDesc, LogText)
			SELECT
				2, 'Un_Beneficiary', B.BeneficiaryID, @Now, @ActionID, 
				LogDesc = 'Bénéficiaire : ' + (H.LastName + ', ' + H.FirstName), 
				LogText =				
					CASE WHEN ISNULL(H.FirstName, '') = '' THEN ''
						 ELSE 'FirstName' + @RecSep + H.FirstName + @RecSep + @CrLf
					END + 
					CASE WHEN ISNULL(H.LastName, '') = '' THEN ''
						 ELSE 'LastName' + @RecSep + H.LastName + @RecSep + @CrLf
					END + 
					CASE WHEN ISNULL(H.BirthDate, 0) <= 0 THEN ''
						 ELSE 'BirthDate' + @RecSep + CONVERT(CHAR(10), H.BirthDate, 20) + @RecSep + @CrLf
					END + 
					CASE WHEN ISNULL(H.DeathDate, 0) <= 0 THEN ''
						 ELSE 'DeathDate' + @RecSep + CONVERT(CHAR(10), H.DeathDate, 20) + @RecSep + @CrLf
					END + 
					'LangID' + @RecSep + H.LangID
 							 + @RecSep + IsNull((Select LangName From  dbo.Mo_Lang Where LangID = H.LangID), '')
							 + @RecSep + @CrLf + 
					'SexID' + @RecSep + H.SexID
 							+ @RecSep + IsNull((Select SexName From  dbo.Mo_Sex Where LangID = 'FRA' AND SexID = H.SexID), '')
							+ @RecSep + @CrLf + 
					CASE WHEN ISNULL(H.SocialNumber, '') = '' THEN ''
							ELSE 'SocialNumber' + @RecSep + H.SocialNumber + @RecSep + @CrLf
					END + 
					CASE WHEN ISNULL(H.PaysID_Origine, '') = '' THEN ''
						 ELSE 'cID_Pays_Origine' + @RecSep + H.PaysID_Origine
											     + @RecSep + IsNull((Select CountryName From Mo_Country WHERE CountryID = H.PaysID_Origine), '')
											     + @RecSep + @CrLf
					END +
					CASE WHEN ISNULL(A.Adresse, '') = '' THEN ''
							ELSE 'Address' + @RecSep + A.Adresse + @RecSep + @CrLf
					END + 
					CASE WHEN ISNULL(A.City, '') = '' THEN ''
							ELSE 'City' + @RecSep + A.City + @RecSep + @CrLf
					END + 
					CASE WHEN ISNULL(A.StateName, '') = '' THEN ''
							ELSE 'StateName' + @RecSep + A.StateName + @RecSep + @CrLf
					END + 
					CASE WHEN ISNULL(A.CountryID, '') = '' THEN ''
							ELSE 'CountryID' + @RecSep + A.CountryID + @RecSep + A.CountryName + @RecSep + @CrLf
					END + 
					CASE WHEN ISNULL(A.ZipCode, '') = '' THEN ''
							ELSE 'ZipCode' + @RecSep + A.ZipCode + @RecSep + @CrLf
					END + 
					CASE WHEN ISNULL(P.Phone1, '') = '' THEN ''
							ELSE 'Phone1' + @RecSep + P.Phone1 + @RecSep + @CrLf
					END + 
					CASE WHEN ISNULL(P.Phone2, '') = '' THEN ''
							ELSE 'Phone2' + @RecSep + P.Phone2 + @RecSep + @CrLf
					END + 
					CASE WHEN ISNULL(P.Fax, '') = '' THEN ''
							ELSE 'Fax' + @RecSep + P.Fax + @RecSep + @CrLf
					END + 
					CASE WHEN ISNULL(P.Mobile, '') = '' THEN ''
							ELSE 'Mobile' + @RecSep + P.Mobile + @RecSep + @CrLf
					END + 
					CASE WHEN ISNULL(P.OtherTel, '') = '' THEN ''
							ELSE 'OtherTel' + @RecSep + P.OtherTel + @RecSep + @CrLf
					END + 
					CASE WHEN ISNULL(P.EMail, '') = '' THEN ''
							ELSE 'EMail' + @RecSep + P.EMail + @RecSep + @CrLf
					END+ 
					CASE WHEN ISNULL(B.iTutorID, 0) = 0 THEN ''
						 ELSE 'iTutorID' + @RecSep + CAST(B.iTutorID AS VARCHAR(30)) 
							 + @RecSep + IsNull((Select LastName + ', ' + FirstName From ProAcces.Mo_Human Where HumanID = B.iTutorID), '') + @RecSep + @CrLf
							 + 'bTutorIsSubscriber' + @RecSep + LTrim(Str(ISNULL(B.bTutorIsSubscriber, 0))) + @RecSep
							 +	CASE WHEN ISNULL(B.bTutorIsSubscriber, 0) = 1 THEN 'Oui' ELSE 'Non' END + @RecSep + @CrLf
					END +
					CASE WHEN ISNULL(B.iTutorID, 0) = 0 THEN ''
						 ELSE 'iTutorID' + @RecSep + CAST(B.iTutorID AS VARCHAR(30)) 
							 + @RecSep + IsNull((Select LastName + ', ' + FirstName From dbo.Mo_Human Where HumanID = B.iTutorID), '') + @RecSep + @CrLf
							 + 'bTutorIsSubscriber' + @RecSep + LTrim(Str(ISNULL(B.bTutorIsSubscriber, 0))) + @RecSep
							 +	CASE WHEN ISNULL(B.bTutorIsSubscriber, 0) = 1 THEN 'Oui' ELSE 'Non' END + @RecSep + @CrLf
					END +
					CASE ISNULL(B.tiPCGType, 1)
						 WHEN 1 THEN
							'tiPCGType' + @RecSep + LTrim(Str(ISNULL(B.tiPCGType, 0))) + @RecSep + 
							CASE WHEN ISNULL(B.bPCGIsSubscriber, 0) = 0 THEN 'Personne' ELSE 'Souscripteur' END + @RecSep + @CrLf
						 WHEN 2 THEN
							'tiPCGType' + @RecSep + LTrim(Str(ISNULL(B.tiPCGType, 0))) + @RecSep + 
							CASE WHEN ISNULL(B.bPCGIsSubscriber, 0) = 0 THEN 'Entreprise' ELSE 'Souscripteur' END + @RecSep + @CrLf
						 ELSE ''
					END + 
					CASE WHEN ISNULL(B.vcPCGFirstName, '') = '' THEN ''
						 ELSE 'vcPCGFirstName' + @RecSep + B.vcPCGFirstName + @RecSep + @CrLf
					END + 
					CASE WHEN ISNULL(B.vcPCGLastName, '') = '' THEN ''
						 ELSE 'vcPCGLastName' + @RecSep + B.vcPCGLastName + @RecSep + @CrLf
					END + 
					CASE WHEN ISNULL(B.vcPCGSINOrEN, '') = '' THEN ''
						 WHEN ISNULL(B.tiPCGType, 1) = 1 THEN 'vcPCGSIN' + @RecSep + B.vcPCGSINOrEN + @RecSep + @CrLf
						 ELSE 'vcPCGEN' + @RecSep + B.vcPCGSINOrEN + @RecSep + @CrLf
					END	+
					CASE WHEN ISNULL(B.ResponsableNEQ, '') = '' THEN ''
						 ELSE 'ResponsableNEQ' + @RecSep + B.ResponsableNEQ + @RecSep + @CrLf
					END	+
					CASE WHEN ISNULL(B.tiCESPState,0) = 0 THEN ''
						 ELSE 'tiCESPState' + @RecSep + LTrim(Str(B.tiCESPState)) 
											+ @RecSep + CASE B.tiCESPState 
															WHEN 1 THEN 'SCEE'
															WHEN 2 THEN 'SCEE et BEC'
															WHEN 3 THEN 'SCEE et SCEE+'
															WHEN 4 THEN 'SCEE, SCEE+ et BEC'
															ELSE '' 
														END 
											+ @RecSep + @CrLf
					END +
					''
				FROM deleted B
					JOIN CTE_Human H ON H.HumanID = B.BeneficiaryID
					LEFT JOIN CTE_Adresse A ON A.SourceID = H.HumanID
					LEFT JOIN CTE_Phone P ON P.SourceID = A.SourceID and P.AdresseID = A.AdresseID

	DELETE FROM B
	FROM dbo.Un_Beneficiary B
		 INNER JOIN deleted D ON D.BeneficiaryID = B.BeneficiaryID
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END


GO
CREATE TRIGGER [ProAcces].[TR_Un_Beneficiary_Ins] ON [ProAcces].[Un_Beneficiary]
    INSTEAD OF INSERT
AS BEGIN
    EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Start'
    -- *** AVERTISSEMENT *** Ce script doit toujours figurer en tête de trigger

    -- Si la table #DisableTrigger est présente, il se pourrait que le trigger
    -- ne soit pas à exécuter
    IF object_id('tempdb..#DisableTrigger') is null 
        CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))
    ELSE 
    BEGIN
        -- Le trigger doit être retrouvé dans la table pour être ignoré
        IF EXISTS (SELECT 1 FROM #DisableTrigger WHERE OBJECT_NAME(@@PROCID) like vcTriggerName)
        BEGIN
            -- Ne pas faire le trigger
            EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Trigger Ignored'
            RETURN
        END
    END

    -- *** FIN AVERTISSEMENT *** 
    INSERT INTO #DisableTrigger VALUES('TR_Un_Beneficiary_Ins')    
    INSERT INTO #DisableTrigger VALUES('TUn_Beneficiary')    

    INSERT INTO dbo.Un_Beneficiary (
        BeneficiaryID, iTutorID, bTutorIsSubscriber, vcPCGSINorEN, vcPCGFirstName, vcPCGLastName, tiPCGType, bPCGIsSubscriber, ResponsableNEQ, tiCESPState, bReleve_Papier, bDevancement_AdmissibilitePAE
        -- Follows not used but not nullable & without default value
        ,ProgramLength, ProgramYear
    )
    SELECT
        BeneficiaryID, iTutorID, bTutorIsSubscriber, vcPCGSINorEN, vcPCGFirstName, vcPCGLastName, tiPCGType, bPCGIsSubscriber, ResponsableNEQ, tiCESPState, bReleve_Papier, bDevancement_AdmissibilitePAE
        -- Follows not used but not nullable & without default value
        , 0, 0
    FROM
        inserted

    UPDATE B
        SET B.bAddressLost = A.bInvalide
    FROM 
        dbo.Un_Beneficiary B JOIN inserted I ON I.BeneficiaryID = B.BeneficiaryID
        JOIN tblGENE_Adresse A ON A.iID_Source = B.BeneficiaryID AND A.dtDate_Debut <= GETDATE()
    WHERE 
        B.bAddressLost <> A.bInvalide

    IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
        DELETE FROM #DisableTrigger WHERE vcTriggerName IN ('TUn_Beneficiary')

    DECLARE @BeneficiaryID int = 0,
            @ConventionID INT,
            @CESP400ID INT,
            @BlobID int,
            @BlobCotisationID int,
            @ConnectID int = 2,
            @DateEntreeREEE date,
            @Now datetime = GetDate(),
            @BlobLigne VARCHAR(MAX),
            @BlobCotisationIds VARCHAR(MAX),
            @iErrorID int,
            @iCompteLigne int,
            @MsgErr varchar(1000)

    DECLARE @TB_SouscripteurNAS TABLE (SocialNumber VARCHAR(75))
    DECLARE @TB_BeneficiaireNAS TABLE (SocialNumber VARCHAR(75))
    DECLARE @TB_Convention TABLE (ConventionID int)
    DECLARE @TB_Blob TABLE (BlobID int, OperID int, CotisationID int, dtTransaction datetime, OperTypeID varchar(5))

    WHILE Exists(Select Top 1 BeneficiaryID From inserted Where BeneficiaryID > @BeneficiaryID) 
    BEGIN
        SELECT @BeneficiaryID = Min(BeneficiaryID) FROM inserted WHERE BeneficiaryID > @BeneficiaryID

        -- Mettre à jour l'état des prévalidations du bénéficiaire
        EXEC @iErrorID = psCONV_EnregistrerPrevalidationPCEE 2, NULL, @BeneficiaryID, NULL, NULL
        If @iErrorID < 0 BEGIN
            SET @MsgErr = 'Error in ' + OBJECT_NAME(@@PROCID) + ' on call to psCONV_EnregistrerPrevalidationPCEE (' + RTrim(Str(@iErrorID)) + ')'
            RAISERROR (@MsgErr, 11, 1)
        END

        -- Si l'on saisi les infos du PR, alors on coche 'Formulaire reçu'
        IF EXISTS(SELECT Top 1 * FROM inserted B JOIN deleted D ON D.BeneficiaryID = B.BeneficiaryID 
                                                 JOIN dbo.Mo_Human H ON H.HumanID = B.BeneficiaryID
                   WHERE B.BeneficiaryID = @BeneficiaryID
                     and IsNull(H.SocialNumber, '') <> ''
                     and (IsNull(D.vcPCGLastName, '') = '' And IsNull(D.vcPCGLastName, '') = '' And IsNull(D.vcPCGSINOrEN, '') = '')
                     and (IsNull(B.vcPCGLastName, '') <> '' And IsNull(B.vcPCGLastName, '') <> '' And IsNull(B.vcPCGSINOrEN, '') <> '')
        ) BEGIN
            DELETE FROM @TB_BeneficiaireNAS
            DELETE FROM @TB_SouscripteurNAS
            DELETE FROM @TB_Convention

            INSERT INTO @TB_BeneficiaireNAS (SocialNumber)
            SELECT DISTINCT SocialNumber FROM dbo.Un_HumanSocialNumber WHERE HumanID = @BeneficiaryID
             UNION SELECT SocialNumber FROM dbo.Mo_Human WHERE HumanID = @BeneficiaryID

            INSERT INTO @TB_SouscripteurNAS (
                SocialNumber
            )
            SELECT DISTINCT 
                SocialNumber 
            FROM 
                dbo.Un_HumanSocialNumber H 
                JOIN dbo.Un_Convention C ON C.SubscriberID = H.HumanID 
            WHERE 
                C.BeneficiaryID = @BeneficiaryID

            ;WITH CTE_LastStartDate As (
                SELECT C.ConventionID, Max(StartDate) as LastDate
                  FROM dbo.Un_ConventionConventionState S JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
                 WHERE C.BeneficiaryID = @BeneficiaryID
                 GROUP BY C.ConventionID
            )
            INSERT INTO @TB_Convention
            SELECT S.ConventionID --, StartDate, S.ConventionStateID
              FROM dbo.Un_ConventionConventionState S JOIN CTE_LastStartDate C ON C.ConventionID = S.ConventionID And C.LastDate = S.StartDate
             WHERE S.ConventionStateID <> 'FRM'

            SET @ConventionID = 0
            WHILE EXISTS(Select Top 1 * From @TB_Convention Where ConventionID > @ConventionID) BEGIN

                SELECT @ConventionID = Min(ConventionID) FROM @TB_Convention WHERE ConventionID > @ConventionID
                DELETE FROM @TB_Blob

                ; WITH CTE_CESP400 as (
                        SELECT iCESP400ID, OperID, CotisationID, dtTransaction
                          FROM dbo.Un_CESP400 C JOIN @TB_BeneficiaireNAS B ON B.SocialNumber = C.vcBeneficiarySIN        -- Gérer les changements de NAS.
                                                JOIN @TB_SouscripteurNAS S ON S.SocialNumber = C.vcSubscriberSINorEN    -- Gérer les changements de NAS.
                         WHERE ConventionID = @ConventionID
                           AND tiCESP400TypeID = 11 --Type cotisation.
                           AND bCESPDemand = 0 --Subvention non-demandée.
                           AND iCESP800ID IS NULL
                           AND iReversedCESP400ID IS NULL -- Pas une annulation
                           AND dtTransaction < @Now
                           AND DATEDIFF(Month, dtTransaction, @Now) <= 36 -- À revoir avec la notion du 7ème jour du mois suivant.
                    )
                INSERT INTO @TB_Blob (BlobID, OperID, CotisationID, dtTransaction, OperTypeID)
                SELECT C4.iCESP400ID, C4.OperID, C4.CotisationID, C4.dtTransaction, O.OperTypeID 
                  FROM CTE_CESP400 C4 LEFT JOIN UN_CESP400 R4 ON C4.iCESP400ID = R4.iReversedCESP400id
                                      LEFT JOIN UN_Oper O ON C4.OperID = O.OperID
                 WHERE R4.iCESP400ID IS NULL -- Pas annulé
                    --AND C4.ConventionID = @ConventionID
                    --AND C4.tiCESP400TypeID = 11 --Type cotisation.
                    --AND C4.bCESPDemand = 0 --Subvention non-demandée.
                    --AND C4.iCESP800ID IS NULL
                    --AND C4.vcBeneficiarySIN IN (SELECT vcNAS FROM @NASBeneficiaire) -- Gérer les changements de NAS.
                    --AND C4.vcSubscriberSINorEN IN (SELECT vcNAS FROM @NASSouscripteur) -- Gérer les changements de NAS.
                    --AND C4.iReversedCESP400ID IS NULL -- Pas une annulation
                    --AND DATEDIFF(Month, C4.dtTransaction, GETDATE()) <= 36 -- À revoir avec la notion du 7ème jour du mois suivant.
                    --AND C4.dtTransaction < GETDATE()

                -- INITIALISATION DES VARIABLES CONTENANT LES BLOBS                            
                SET @BlobLigne            = ''
                SET @BlobCotisationIds    = ''
                SET @iCompteLigne            = 0

                SET @CESP400ID = 0
                WHILE EXISTS(Select Top 1 BlobID From @TB_Blob Where BlobID > @CESP400ID) 
                BEGIN
                    SELECT @CESP400ID = Min(BlobID) FROM @TB_Blob WHERE BlobID > @CESP400ID

                    SELECT @BlobLigne = @BlobLigne + 'Un_Oper' + ';' + CAST(@iCompteLigne AS VARCHAR(10)) + ';' 
                                                                     + CAST(ISNULL(OperID,'') AS VARCHAR(8)) + ';'
                                                                     + CAST(@ConnectID AS VARCHAR(10)) + ';'
                                                                     + CAST(ISNULL(OperTypeID,'') AS VARCHAR(10)) + ';' 
                                                                     + ';' 
                                                                     + CONVERT(VARCHAR(25), ISNULL(dtTransaction,''), 121) 
                                                                     + CHAR(13) + CHAR(10),
                           @BlobCotisationIds = @BlobCotisationIds + CAST(ISNULL(CotisationID, '') AS VARCHAR(10)) + ','
                      FROM @TB_Blob
                     WHERE BlobID = @CESP400ID
                END

                IF (RTRIM(LTRIM(@BlobCotisationIds)) <> '' AND RTRIM(LTRIM(@BlobCotisationIds)) <> ',')
                BEGIN
                    -- INSERTION DES BLOBS
                    EXECUTE @BlobID = dbo.IU_CRI_BLOB 0, @BlobLigne
                    EXECUTE @BlobCotisationID = dbo.IU_CRI_BLOB 0, @BlobCotisationIds
                            
                    -- RENVERSEMENT ET RENVOIS DES TRANSACTIONS
                    EXEC dbo.IU_UN_ReSendCotisationCESP400 @ConventionID, @BlobCotisationID, @BlobID, @ConnectID,  1 -- 2010-04-29 : JFG : Ajout de @bSansVerificationPCEE400
                END                
            END
        END

        IF EXISTS(SELECT TOP 1 B.* FROM dbo.Un_Beneficiary B JOIN deleted D ON D.BeneficiaryID = B.BeneficiaryID 
                   WHERE B.BeneficiaryID = D.BeneficiaryID 
                     and (  B.iTutorID <> D.iTutorID 
                            OR IsNull(B.tiCESPState, 0) <> IsNull(D.tiCESPState, 0) 
                            OR IsNull(B.vcPCGSINOrEN, '')  <> IsNull(D.vcPCGSINOrEN, '')  
                            OR IsNull(B.vcPCGFirstName, '')  <> IsNull(D.vcPCGFirstName, '')  
                            OR IsNull(B.vcPCGLastName, '')  <> IsNull(D.vcPCGLastName, '') 
                         )
        ) BEGIN
            -- Appelle de la procédure stockée qui gère les enregistrements 100, 200, et 400 de toutes les conventions du bénéficiaire.
            EXECUTE @iErrorID = TT_UN_CESPOfConventions 2, @BeneficiaryID, 0, 0
            If @iErrorID <= 0 BEGIN
                SET @MsgErr = 'Error in ' + OBJECT_NAME(@@PROCID) + ' on call to TT_UN_CESPOfConventions (' + RTrim(Str(@iErrorID)) + ')'
                RAISERROR (@MsgErr, 11, 1)
            END

            -- Obtenir la bonne convention BEC
            SET @ConventionID = dbo.fnCONV_ObtenirConventionBEC(@BeneficiaryID, 0, NULL)

            -- On a récupéré un BEC Actif sur une convention et les données du responsable principal ont changé
            IF (@ConventionID > 0 AND
                -- Vérifier s'il y a un changement de principal responsable ou si l'une ou plusieurs données du principal responsable ont changé
                EXISTS(SELECT TOP 1 B.* FROM inserted B JOIN deleted D ON D.BeneficiaryID = B.BeneficiaryID 
                        WHERE B.BeneficiaryID = D.BeneficiaryID 
                          AND ( ISNULL(B.vcPCGSINOrEN, '')  <> IsNull(D.vcPCGSINOrEN, '')  
                                OR IsNull(B.vcPCGFirstName, '')  <> IsNull(D.vcPCGFirstName, '')  
                                OR IsNull(B.vcPCGLastName, '')  <> IsNull(D.vcPCGLastName, '') 
                              )
                      )
            ) BEGIN
                -- On a récupéré un BEC Actif sur une convention et les données du responsable principal ont changé
                -- Création d'une nouvelle demande de BEC
                BEGIN TRY   
                    IF dbo.fnCONV_ObtenirStatutConventionEnDate(@ConventionID, GETDATE()) = 'REE'
                    BEGIN
                        EXECUTE @iErrorID = dbo.psPCEE_CreerDemandeBec @ConventionID        
                        If @iErrorID < 0 BEGIN
                            SET @MsgErr = 'Error in ' + OBJECT_NAME(@@PROCID) + ' on call to psPCEE_CreerDemandeBec (' + RTrim(Str(@iErrorID)) + ')'
                            RAISERROR (@MsgErr, 11, 1)
                        END
                    END
                END TRY
                BEGIN CATCH
                    -- RÉCUPÉRATION DES INFORMATIONS CONCERNANT L'ERREUR
                    SET @MsgErr = 'Error in psPCEE_CreerDemandeBec (' + REPLACE(ERROR_MESSAGE(),'%',' ') + ')'
                    RAISERROR (@MsgErr, 11, 1)

                    IF @iErrorID IS NULL
                        SET @iErrorID = -99
                END CATCH
            END
        END
    END

    If @iErrorID < 0
        ROLLBACK TRANSACTION

    DECLARE @RecSep CHAR(1) = CHAR(30),
            @CrLf CHAR(2) = CHAR(13) + CHAR(10),
            @ActionID int = (SELECT LogActionID FROM CRQ_LogAction WHERE LogActionShortName = 'I'),
            @iID_Utilisateur INT = (SELECT iID_Utilisateur_Systeme FROM dbo.Un_Def)

    ;WITH CTE_Human (HumanID, FirstName, LastName, SexID, LangID, SocialNumber, PaysID_Origine, BirthDate, DeathDate) 
    as (
        SELECT HumanID, FirstName, LastName, SexID, LangID, SocialNumber, cID_Pays_Origine, BirthDate, DeathDate
          FROM ProAcces.Mo_Human H
               JOIN inserted I ON H.HumanID = I.BeneficiaryID
    )
    INSERT INTO CRQ_Log (ConnectID, LogTableName, LogCodeID, LogTime, LogActionID, LogDesc, LogText)
    SELECT
        2, 'Un_Beneficiary', B.BeneficiaryID, @Now, @ActionID, 
        LogDesc = 'Bénéficiaire : ' + (H.LastName + ', ' + H.FirstName), 
        LogText =  CASE WHEN ISNULL(H.FirstName, '') = '' THEN ''
                        ELSE 'FirstName' + @RecSep + H.FirstName + @RecSep + @CrLf
                   END + 
                   CASE WHEN ISNULL(H.LastName, '') = '' THEN ''
                        ELSE 'LastName' + @RecSep + H.LastName + @RecSep + @CrLf
                   END + 
                   CASE WHEN ISNULL(H.BirthDate, 0) <= 0 THEN ''
                        ELSE 'BirthDate' + @RecSep + CONVERT(CHAR(10), H.BirthDate, 20) + @RecSep + @CrLf
                   END + 
                   CASE WHEN ISNULL(H.DeathDate, 0) <= 0 THEN ''
                        ELSE 'DeathDate' + @RecSep + CONVERT(CHAR(10), H.DeathDate, 20) + @RecSep + @CrLf
                   END + 
                   'LangID' + @RecSep + H.LangID + @RecSep + IsNull((Select LangName From  dbo.Mo_Lang Where LangID = H.LangID), '') + @RecSep + @CrLf + 
                   'SexID' + @RecSep + H.SexID + @RecSep + IsNull((Select SexName From  dbo.Mo_Sex Where LangID = 'FRA' AND SexID = H.SexID), '') + @RecSep + @CrLf + 
                   CASE WHEN ISNULL(H.SocialNumber, '') = '' THEN ''
                        ELSE 'SocialNumber' + @RecSep + H.SocialNumber + @RecSep + @CrLf
                   END + 
                   CASE WHEN ISNULL(H.PaysID_Origine, '') = '' THEN ''
                        ELSE 'cID_Pays_Origine' + @RecSep + H.PaysID_Origine + @RecSep + IsNull((Select CountryName From Mo_Country WHERE CountryID = H.PaysID_Origine), '') + @RecSep + @CrLf
                   END +
                   CASE WHEN ISNULL(B.iTutorID, 0) = 0 THEN ''
                        ELSE 'iTutorID' + @RecSep + CAST(B.iTutorID AS VARCHAR(30)) + @RecSep + IsNull((Select LastName + ', ' + FirstName From dbo.Mo_Human Where HumanID = B.iTutorID), '') + @RecSep + @CrLf +
                             'bTutorIsSubscriber' + @RecSep + LTrim(Str(ISNULL(B.bTutorIsSubscriber, 0))) + @RecSep + CASE WHEN ISNULL(B.bTutorIsSubscriber, 0) = 1 THEN 'Oui' ELSE 'Non' END + @RecSep + @CrLf
                    END +
                    CASE ISNULL(B.tiPCGType, 0)
                        WHEN 1 THEN 'tiPCGType' + @RecSep + LTrim(Str(ISNULL(B.tiPCGType, 0))) + @RecSep + 
                                    CASE WHEN ISNULL(B.bPCGIsSubscriber, 0) = 0 THEN 'Personne' ELSE 'Souscripteur' END + @RecSep + @CrLf
                        WHEN 2 THEN 'tiPCGType' + @RecSep + LTrim(Str(ISNULL(B.tiPCGType, 0))) + @RecSep + 
                                    CASE WHEN ISNULL(B.bPCGIsSubscriber, 0) = 0 THEN 'Entreprise' ELSE 'Souscripteur' END + @RecSep + @CrLf
                        ELSE ''
                    END + 
                    CASE WHEN ISNULL(B.vcPCGFirstName, '') = '' THEN '' 
                         ELSE 'vcPCGFirstName' + @RecSep + B.vcPCGFirstName + @RecSep + @CrLf
                    END + 
                    CASE WHEN ISNULL(B.vcPCGLastName, '') = '' THEN ''
                         ELSE 'vcPCGLastName' + @RecSep + B.vcPCGLastName + @RecSep + @CrLf
                    END + 
                    CASE WHEN ISNULL(B.vcPCGSINOrEN, '') = '' THEN ''
                         WHEN ISNULL(B.tiPCGType, 1) = 1 THEN 'vcPCGSIN' + @RecSep + B.vcPCGSINOrEN + @RecSep + @CrLf
                         ELSE 'vcPCGEN' + @RecSep + B.vcPCGSINOrEN + @RecSep + @CrLf
                    END +
                    CASE WHEN ISNULL(B.ResponsableNEQ, '') = '' THEN ''
                         ELSE 'ResponsableNEQ' + @RecSep + B.ResponsableNEQ + @RecSep + @CrLf
                    END +
                    CASE WHEN ISNULL(B.tiCESPState,0) = 0 THEN ''
                         ELSE 'tiCESPState' + @RecSep + LTrim(Str(B.tiCESPState)) 
                                            + @RecSep + CASE B.tiCESPState 
                                                            WHEN 1 THEN 'SCEE'
                                                            WHEN 2 THEN 'SCEE et BEC'
                                                            WHEN 3 THEN 'SCEE et SCEE+'
                                                            WHEN 4 THEN 'SCEE, SCEE+ et BEC'
                                                            ELSE '' 
                                                        END 
                                            + @RecSep + @CrLf
                    END +
                    'bReleve_Papier' + @RecSep + LTrim(Str(B.bReleve_Papier)) + @RecSep + CASE B.bReleve_Papier WHEN 0 THEN 'Non' ELSE 'Oui' END + @RecSep + @CrLf +
                    'bDevancement_AdmissibilitePAE' + @RecSep + LTrim(Str(B.bReleve_Papier)) + @RecSep + CASE B.bDevancement_AdmissibilitePAE WHEN 0 THEN 'Non' ELSE 'Oui' END + @RecSep + @CrLf +
                    ''
        FROM 
            ProAcces.Un_Beneficiary B
            JOIN CTE_Human H ON H.HumanID = B.BeneficiaryID

    IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
        DELETE FROM #DisableTrigger WHERE vcTriggerName IN ('TR_Un_Beneficiary_Ins')
    EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END
GO
CREATE TRIGGER [ProAcces].[TR_Un_Beneficiary_Upd] ON [ProAcces].[Un_Beneficiary]
    INSTEAD OF UPDATE
AS BEGIN
    EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Start'
    PRINT 'transcount : ' + STR(@@TRANCOUNT)
    -- *** AVERTISSEMENT *** Ce script doit toujours figurer en tête de trigger

    -- Si la table #DisableTrigger est présente, il se pourrait que le trigger
    -- ne soit pas à exécuter
    IF object_id('tempdb..#DisableTrigger') is null 
        CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))
    ELSE 
    BEGIN
        -- Le trigger doit être retrouvé dans la table pour être ignoré
        IF EXISTS (SELECT 1 FROM #DisableTrigger WHERE OBJECT_NAME(@@PROCID) like vcTriggerName)
        BEGIN
            -- Ne pas faire le trigger
            EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Trigger Ignored'
            RETURN
        END
    END

    -- *** FIN AVERTISSEMENT *** 
    INSERT INTO #DisableTrigger VALUES('TR_Un_Beneficiary_Upd')    
    INSERT INTO #DisableTrigger VALUES('TUn_Beneficiary')    

    UPDATE TB SET
        iTutorID = I.iTutorID,
        bTutorIsSubscriber = I.bTutorIsSubscriber,
        vcPCGSINorEN = I.vcPCGSINorEN,
        vcPCGFirstName = I.vcPCGFirstName,
        vcPCGLastName = I.vcPCGLastName,
        tiPCGType = I.tiPCGType,
        bPCGIsSubscriber = I.bPCGIsSubscriber,
        tiCESPState = I.tiCESPState,
        bReleve_Papier = I.bReleve_Papier,
        ResponsableNEQ = I.ResponsableNEQ,
        bDevancement_AdmissibilitePAE = I.bDevancement_AdmissibilitePAE
    FROM
        dbo.Un_Beneficiary TB
        INNER JOIN inserted I ON I.BeneficiaryID = TB.BeneficiaryID

    IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
        DELETE FROM #DisableTrigger WHERE vcTriggerName IN ('TUn_Beneficiary')

    DECLARE @BeneficiaryID int = 0,
            @ConventionID INT,
            @CESP400ID INT,
            @BlobID int,
            @BlobCotisationID int,
            @ConnectID int = 2,
            @DateEntreeREEE date,
            @Now datetime = GetDate(),
            @BlobLigne VARCHAR(MAX),
            @BlobCotisationIds VARCHAR(MAX),
            @iErrorID int,
            @iCompteLigne int,
            @MsgErr varchar(1000)

    DECLARE @TB_SouscripteurNAS TABLE (SocialNumber VARCHAR(75))
    DECLARE @TB_BeneficiaireNAS TABLE (SocialNumber VARCHAR(75))
    DECLARE @TB_Convention TABLE (ConventionID int)
    DECLARE @TB_Blob TABLE (BlobID int, OperID int, CotisationID int, dtTransaction datetime, OperTypeID varchar(5))

    WHILE Exists(Select Top 1 BeneficiaryID From inserted Where BeneficiaryID > @BeneficiaryID) 
    BEGIN
        SELECT @BeneficiaryID = Min(BeneficiaryID) FROM inserted WHERE BeneficiaryID > @BeneficiaryID

        -- Mettre à jour l'état des prévalidations du bénéficiaire
        EXEC @iErrorID = psCONV_EnregistrerPrevalidationPCEE 2, NULL, @BeneficiaryID, NULL, NULL
        If @iErrorID < 0 BEGIN
            SET @MsgErr = 'Error in ' + OBJECT_NAME(@@PROCID) + ' on call to psCONV_EnregistrerPrevalidationPCEE (' + RTrim(Str(@iErrorID)) + ')'
            RAISERROR (@MsgErr, 11, 1)
        END

        -- Si l'on saisi les infos du PR, alors on coche 'Formulaire reçu'
        IF EXISTS(Select Top 1 * From inserted B JOIN deleted D ON D.BeneficiaryID = B.BeneficiaryID 
                                                 JOIN dbo.Mo_Human H ON H.HumanID = B.BeneficiaryID
                   Where B.BeneficiaryID = @BeneficiaryID
                     and IsNull(H.SocialNumber, '') <> ''
                     and (IsNull(D.vcPCGLastName, '') = '' And IsNull(D.vcPCGLastName, '') = '' And IsNull(D.vcPCGSINOrEN, '') = '')
                     and (IsNull(B.vcPCGLastName, '') <> '' And IsNull(B.vcPCGLastName, '') <> '' And IsNull(B.vcPCGSINOrEN, '') <> '')
                 )
        BEGIN
            DELETE FROM @TB_BeneficiaireNAS
            DELETE FROM @TB_SouscripteurNAS
            DELETE FROM @TB_Convention

            INSERT INTO @TB_BeneficiaireNAS (SocialNumber)
            SELECT DISTINCT SocialNumber FROM dbo.Un_HumanSocialNumber WHERE HumanID = @BeneficiaryID
            UNION SELECT SocialNumber FROM dbo.Mo_Human WHERE HumanID = @BeneficiaryID

            INSERT INTO @TB_SouscripteurNAS (SocialNumber)
            SELECT DISTINCT SocialNumber 
              FROM dbo.Un_HumanSocialNumber H 
                   JOIN dbo.Un_Convention C ON C.SubscriberID = H.HumanID 
             WHERE C.BeneficiaryID = @BeneficiaryID

            ;WITH CTE_LastStartDate As (
                    SELECT C.ConventionID, Max(StartDate) as LastDate
                      FROM dbo.Un_ConventionConventionState S JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
                     WHERE C.BeneficiaryID = @BeneficiaryID
                     GROUP BY C.ConventionID
                )
            INSERT INTO @TB_Convention
            SELECT S.ConventionID --, StartDate, S.ConventionStateID
              FROM dbo.Un_ConventionConventionState S 
                   JOIN CTE_LastStartDate C ON C.ConventionID = S.ConventionID And C.LastDate = S.StartDate
              WHERE S.ConventionStateID <> 'FRM'

            SET @ConventionID = 0
            WHILE EXISTS(Select Top 1 * From @TB_Convention Where ConventionID > @ConventionID) 
            BEGIN
                SELECT @ConventionID = Min(ConventionID) FROM @TB_Convention WHERE ConventionID > @ConventionID
                DELETE FROM @TB_Blob

                ;WITH CTE_CESP400 as (
                    SELECT iCESP400ID, OperID, CotisationID, dtTransaction
                      FROM dbo.Un_CESP400 C JOIN @TB_BeneficiaireNAS B ON B.SocialNumber = C.vcBeneficiarySIN        -- Gérer les changements de NAS.
                                            JOIN @TB_SouscripteurNAS S ON S.SocialNumber = C.vcSubscriberSINorEN    -- Gérer les changements de NAS.
                     WHERE ConventionID = @ConventionID
                       AND tiCESP400TypeID = 11 --Type cotisation.
                       AND bCESPDemand = 0 --Subvention non-demandée.
                       AND iCESP800ID IS NULL
                       AND iReversedCESP400ID IS NULL -- Pas une annulation
                       AND dtTransaction < @Now
                       AND DATEDIFF(Month, dtTransaction, @Now) <= 36 -- À revoir avec la notion du 7ème jour du mois suivant.
                )
                INSERT INTO @TB_Blob (BlobID, OperID, CotisationID, dtTransaction, OperTypeID)
                SELECT C4.iCESP400ID, C4.OperID, C4.CotisationID, C4.dtTransaction, O.OperTypeID 
                  FROM CTE_CESP400 C4 LEFT JOIN UN_CESP400 R4 ON C4.iCESP400ID = R4.iReversedCESP400id
                                      LEFT JOIN UN_Oper O ON C4.OperID = O.OperID
                 WHERE R4.iCESP400ID IS NULL -- Pas annulé
                    --AND C4.ConventionID = @ConventionID
                    --AND C4.tiCESP400TypeID = 11 --Type cotisation.
                    --AND C4.bCESPDemand = 0 --Subvention non-demandée.
                    --AND C4.iCESP800ID IS NULL
                    --AND C4.vcBeneficiarySIN IN (SELECT vcNAS FROM @NASBeneficiaire) -- Gérer les changements de NAS.
                    --AND C4.vcSubscriberSINorEN IN (SELECT vcNAS FROM @NASSouscripteur) -- Gérer les changements de NAS.
                    --AND C4.iReversedCESP400ID IS NULL -- Pas une annulation
                    --AND DATEDIFF(Month, C4.dtTransaction, GETDATE()) <= 36 -- À revoir avec la notion du 7ème jour du mois suivant.
                    --AND C4.dtTransaction < GETDATE()

                -- INITIALISATION DES VARIABLES CONTENANT LES BLOBS                            
                SET @BlobLigne            = ''
                SET @BlobCotisationIds    = ''
                SET @iCompteLigne            = 0

                SET @CESP400ID = 0
                WHILE EXISTS(Select Top 1 BlobID From @TB_Blob Where BlobID > @CESP400ID) 
                BEGIN
                    SELECT @CESP400ID = Min(BlobID) FROM @TB_Blob WHERE BlobID > @CESP400ID

                    SELECT @BlobLigne = @BlobLigne + 'Un_Oper' + ';' + CAST(@iCompteLigne AS VARCHAR(10)) + ';' 
                                                               + CAST(ISNULL(OperID,'') AS VARCHAR(8)) + ';'
                                                               + CAST(@ConnectID AS VARCHAR(10)) + ';'
                                                               + CAST(ISNULL(OperTypeID,'') AS VARCHAR(10)) + ';' 
                                                               + ';' 
                                                               + CONVERT(VARCHAR(25), ISNULL(dtTransaction,''), 121) 
                                                               + CHAR(13) + CHAR(10),
                           @BlobCotisationIds = @BlobCotisationIds + CAST(ISNULL(CotisationID, '') AS VARCHAR(10)) + ','
                      FROM @TB_Blob
                     WHERE BlobID = @CESP400ID
                END

                IF (RTRIM(LTRIM(@BlobCotisationIds)) <> '' AND RTRIM(LTRIM(@BlobCotisationIds)) <> ',')
                BEGIN
                    -- INSERTION DES BLOBS
                    EXECUTE @BlobID = dbo.IU_CRI_BLOB 0, @BlobLigne
                    EXECUTE @BlobCotisationID = dbo.IU_CRI_BLOB 0, @BlobCotisationIds
                            
                    -- RENVERSEMENT ET RENVOIS DES TRANSACTIONS
                    EXEC dbo.IU_UN_ReSendCotisationCESP400 @ConventionID, @BlobCotisationID, @BlobID, @ConnectID,  1 -- 2010-04-29 : JFG : Ajout de @bSansVerificationPCEE400
                END                
            END
        END

        IF EXISTS(Select Top 1 * From dbo.Un_Beneficiary B JOIN deleted D ON D.BeneficiaryID = B.BeneficiaryID 
                   WHERE B.tiCESPState IN (2,4) And IsNull(D.tiCESPState, 0) NOT IN (2,4)
                 )
        BEGIN
            -- Récupérer la bonne convention BEC.
            SET @ConventionID = dbo.fnCONV_ObtenirConventionBEC(@BeneficiaryID, 0, NULL)
            SET @DateEntreeREEE = (SELECT dtRegStartDate FROM dbo.UN_Convention WHERE ConventionID = @ConventionID)

            -- S'il y a une convention BEC et une date dtRegStartDAte, alors on génère la transaction 400.
            IF (@ConventionID > 0) AND (@DateEntreeREEE <= @Now) -- Ne pas créer de BEC avant la date d'entrée en REEE
                EXEC dbo.TT_UN_CLB @ConventionID
        END

        IF EXISTS(SELECT TOP 1 B.* FROM dbo.Un_Beneficiary B JOIN deleted D ON D.BeneficiaryID = B.BeneficiaryID 
                   WHERE B.BeneficiaryID = D.BeneficiaryID 
                     and (  B.iTutorID <> D.iTutorID 
                            OR ISNULL(B.tiCESPState, 0) <> IsNull(D.tiCESPState, 0) 
                            OR IsNull(B.vcPCGSINOrEN, '')  <> IsNull(D.vcPCGSINOrEN, '')  
                            OR IsNull(B.vcPCGFirstName, '')  <> IsNull(D.vcPCGFirstName, '')  
                            OR IsNull(B.vcPCGLastName, '')  <> IsNull(D.vcPCGLastName, '') 
                         )
                 ) 
        BEGIN
            -- Appelle de la procédure stockée qui gère les enregistrements 100, 200, et 400 de toutes les conventions du bénéficiaire.
            EXECUTE @iErrorID = TT_UN_CESPOfConventions 2, @BeneficiaryID, 0, 0
            If @iErrorID <= 0 BEGIN
                SET @MsgErr = 'Error in ' + OBJECT_NAME(@@PROCID) + ' on call to TT_UN_CESPOfConventions (' + RTrim(Str(@iErrorID)) + ')'
                RAISERROR (@MsgErr, 11, 1)
            END

            -- Obtenir la bonne convention BEC
            SET @ConventionID = dbo.fnCONV_ObtenirConventionBEC(@BeneficiaryID, 0, NULL)

            -- On a récupéré un BEC Actif sur une convention et les données du responsable principal ont changé
            IF (@ConventionID > 0 AND
                -- Vérifier s'il y a un changement de principal responsable ou si l'une ou plusieurs données du principal responsable ont changé
                EXISTS(SELECT TOP 1 B.* FROM inserted B JOIN deleted D ON D.BeneficiaryID = B.BeneficiaryID 
                        WHERE B.BeneficiaryID = D.BeneficiaryID 
                          AND ( IsNull(B.vcPCGSINOrEN, '')  <> IsNull(D.vcPCGSINOrEN, '')  
                                OR IsNull(B.vcPCGFirstName, '')  <> IsNull(D.vcPCGFirstName, '')  
                                OR IsNull(B.vcPCGLastName, '')  <> IsNull(D.vcPCGLastName, '') 
                              )
                      )
            ) BEGIN
                -- On a récupéré un BEC Actif sur une convention et les données du responsable principal ont changé
                -- Création d'une nouvelle demande de BEC
                BEGIN TRY   
                    IF dbo.fnCONV_ObtenirStatutConventionEnDate(@ConventionID, GETDATE()) = 'REE'
                    BEGIN
                        EXECUTE @iErrorID = dbo.psPCEE_CreerDemandeBec @ConventionID        
                        If @iErrorID < 0 BEGIN
                            SET @MsgErr = 'Error in ' + OBJECT_NAME(@@PROCID) + ' on call to psPCEE_CreerDemandeBec (' + RTrim(Str(@iErrorID)) + ')'
                            RAISERROR (@MsgErr, 11, 1)
                        END
                    END
                END TRY
                BEGIN CATCH
                    -- RÉCUPÉRATION DES INFORMATIONS CONCERNANT L'ERREUR
                    SET @MsgErr = 'Error in psPCEE_CreerDemandeBec (' + REPLACE(ERROR_MESSAGE(),'%',' ') + ')'
                    RAISERROR (@MsgErr, 11, 1)

                    IF @iErrorID IS NULL
                        SET @iErrorID = -99
                END CATCH
            END
        END    
    END

    If @iErrorID < 0
        ROLLBACK TRANSACTION

    DECLARE @RecSep CHAR(1) = CHAR(30)
        ,    @CrLf CHAR(2) = CHAR(13) + CHAR(10)
        ,    @ActionID int = (SELECT LogActionID FROM CRQ_LogAction WHERE LogActionShortName = 'U')
        ,    @iID_Utilisateur INT = (SELECT iID_Utilisateur_Systeme FROM dbo.Un_Def)

    ;WITH CTE_BeneficiaryNew as (
        SELECT
            B.BeneficiaryID, IsNull(B.iTutorID, 0) as TutorID, IsNull(B.bTutorIsSubscriber, 0) as TutorIsSubscriber, IsNull(B.vcPCGSINorEN, '') as PCGSINorEN, 
            IsNull(B.vcPCGFirstName, '') as PCGFirstName, IsNull(B.vcPCGLastName, '') as PCGLastName, IsNull(B.tiPCGType, 0) as PCGType, IsNull(B.bPCGIsSubscriber, 0) as PCGIsSubscriber,
            IsNull(B.ResponsableNEQ, 0) as ResponsableNEQ, IsNull(B.bReleve_Papier, 0) as bReleve_Papier, B.tiCESPState, B.bDevancement_AdmissibilitePAE
        FROM  
            ProAcces.Un_Beneficiary B 
            JOIN inserted I ON I.BeneficiaryID = B.BeneficiaryID
    ),
    CTE_BeneficiaryOld as (
        SELECT
            BeneficiaryID, IsNull(iTutorID, 0) as TutorID, IsNull(bTutorIsSubscriber, 0) as TutorIsSubscriber, IsNull(vcPCGSINorEN, '') as PCGSINorEN, 
            IsNull(vcPCGFirstName, '') as PCGFirstName, IsNull(vcPCGLastName, '') as PCGLastName, IsNull(tiPCGType, 0) as PCGType, IsNull(bPCGIsSubscriber, 0) as PCGIsSubscriber,
            IsNull(ResponsableNEQ, 0) as ResponsableNEQ, IsNull(bReleve_Papier, 0) as bReleve_Papier, tiCESPState, bDevancement_AdmissibilitePAE
        FROM
            deleted
    )
    INSERT INTO CRQ_Log (ConnectID, LogCodeID, LogTime, LogActionID, LogTableName, LogDesc, LogText)
    SELECT
        2, New.BeneficiaryID, @Now, @ActionID, 
        LogTableName = 'Un_Beneficiary', 
        LogDesc = 'Bénéficiaire : ' + (Select LastName + ', ' + FirstName From ProAcces.Mo_Human Where HumanID = New.BeneficiaryID), 
        LogText = CASE WHEN New.TutorID = Old.TutorID THEN ''
                       ELSE 'iTutorID' + @RecSep + Str(Old.TutorID) + @RecSep + Str(New.TutorID) 
                                       + @RecSep + IsNull((Select LastName + ', ' + FirstName From ProAcces.Mo_Human Where HumanID = Old.TutorID), '') 
                                       + @RecSep + IsNull((Select LastName + ', ' + FirstName From ProAcces.Mo_Human Where HumanID = New.TutorID), '')  
                                       + @RecSep + @CrLf
                  END +
                  CASE WHEN (Old.PCGIsSubscriber <> New.PCGIsSubscriber) Or (Old.PCGType <> New.PCGType) OR (Old.PCGLastName <> New.PCGLastName) OR 
                            (Old.PCGFirstName <> New.PCGFirstName) OR (Old.PCGSINOrEN <> New.PCGSINOrEN) --OR (New.StateCompanyNo <> New.StateCompanyNo)
                           THEN 'tiPCGType' + @RecSep +
                                    CASE Old.PCGType
                                        WHEN 1 THEN CASE Old.PCGIsSubscriber WHEN 0 THEN 'Personne' ELSE 'Souscripteur' END
                                        WHEN 2 THEN CASE Old.PCGIsSubscriber WHEN 0 THEN 'Entreprise' ELSE 'Souscripteur' END
                                        ELSE ''
                                    END + @RecSep +
                                    CASE New.PCGType
                                        WHEN 1 THEN CASE New.PCGIsSubscriber WHEN 0 THEN 'Personne' ELSE 'Souscripteur' END
                                        WHEN 2 THEN CASE New.PCGIsSubscriber WHEN 0 THEN 'Entreprise' ELSE 'Souscripteur' END
                                        ELSE ''
                                    END + @RecSep + @CrLf +
                                'vcPCGFirstName' + @RecSep + Old.PCGFirstName + @RecSep + New.PCGFirstName + @RecSep + @CrLf +
                                'vcPCGLastName' + @RecSep + Old.PCGLastName + @RecSep + New.PCGLastName + @RecSep + @CrLf +
                                    CASE New.PCGType WHEN 1 THEN 'vcPCGSIN' 
                                                     ELSE 'vcPCGEN' 
                                    END + @RecSep + Old.PCGSINOrEN + @RecSep + New.PCGSINOrEN + @RecSep + @CrLf +
                                CASE WHEN Old.ResponsableNEQ = new.ResponsableNEQ THEN ''
                                     ELSE 'ResponsableNEQ' + @RecSep + Old.ResponsableNEQ + @RecSep + New.ResponsableNEQ + @RecSep + @CrLf
                                END
                       ELSE ''
                END +
                CASE WHEN Old.tiCESPState = New.tiCESPState THEN ''
                     ELSE 'tiCESPState' + @RecSep + LTrim(Str(Old.tiCESPState)) + @RecSep + LTrim(Str(New.tiCESPState))
                                        + @RecSep + CASE Old.tiCESPState 
                                                        WHEN 1 THEN 'SCEE'
                                                        WHEN 2 THEN 'SCEE et BEC'
                                                        WHEN 3 THEN 'SCEE et SCEE+'
                                                        WHEN 4 THEN 'SCEE, SCEE+ et BEC'
                                                        ELSE '' 
                                                    END 
                                        + @RecSep + CASE New.tiCESPState 
                                                        WHEN 1 THEN 'SCEE'
                                                        WHEN 2 THEN 'SCEE et BEC'
                                                        WHEN 3 THEN 'SCEE et SCEE+'
                                                        WHEN 4 THEN 'SCEE, SCEE+ et BEC'
                                                        ELSE '' 
                                                    END
                                        + @RecSep + @CrLf
                END +
                CASE WHEN Old.bReleve_Papier = New.bReleve_Papier THEN ''
                     ELSE 'bReleve_Papier' + @RecSep + LTrim(Str(Old.bReleve_Papier)) + @RecSep + LTrim(Str(New.bReleve_Papier))
                                           + @RecSep + CASE Old.bReleve_Papier WHEN 0 THEN 'Non' ELSE 'Oui' END 
                                           + @RecSep + CASE New.bReleve_Papier WHEN 0 THEN 'Non' ELSE 'Oui' END
                                           + @RecSep + @CrLf
                END +
                CASE WHEN Old.bDevancement_AdmissibilitePAE = New.bDevancement_AdmissibilitePAE THEN ''
                     ELSE 'bDevancement_AdmissibilitePAE' + @RecSep + LTrim(Str(Old.bDevancement_AdmissibilitePAE)) + @RecSep + LTrim(Str(New.bDevancement_AdmissibilitePAE))
                                           + @RecSep + CASE Old.bDevancement_AdmissibilitePAE WHEN 0 THEN 'Non' ELSE 'Oui' END 
                                           + @RecSep + CASE New.bDevancement_AdmissibilitePAE WHEN 0 THEN 'Non' ELSE 'Oui' END
                                           + @RecSep + @CrLf
                END +
                ''
    FROM    
        CTE_BeneficiaryNew New
        JOIN CTE_BeneficiaryOld Old ON Old.BeneficiaryID = New.BeneficiaryID
        --JOIN ProAcces.Mo_Human H ON H.HumanID = New.BeneficiaryID
    WHERE
        Old.TutorID <> New.TutorID
        OR Old.PCGType <> New.PCGType
        OR Old.PCGLastName <> New.PCGLastName
        OR Old.PCGFirstName <> New.PCGFirstName
        OR Old.PCGSINOrEN <> New.PCGSINOrEN
        OR Old.PCGIsSubscriber <> New.PCGIsSubscriber
        OR Old.tiCESPState <> New.tiCESPState
        OR Old.bReleve_Papier <> New.bReleve_Papier
        OR old.bDevancement_AdmissibilitePAE <> New.bDevancement_AdmissibilitePAE

    IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
        DELETE FROM #DisableTrigger WHERE vcTriggerName IN ('TR_Un_Beneficiary_Upd')
    EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END
GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Contient les données spécifiques au bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'ProAcces', @level1type = N'VIEW', @level1name = N'Un_Beneficiary';

