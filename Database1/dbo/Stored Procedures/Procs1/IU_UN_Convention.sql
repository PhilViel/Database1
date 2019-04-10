/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 : IU_UN_Convention
Description         : Sauvegarde d'ajouts/modifications de conventions
Valeurs de retours  : >0  :	Tout à fonctionn‚
                      <=0 :	Erreur SQL

Exemple d'appel		:

Note                :							2004-06-01	Bruno Lapointe			Création
								ADX0000915	BR	2003-10-15	Bruno Lapointe			Gestion du champs ID unqiue de texte du diplôme. 
								ADX0000589	IA	2004-11-19	Bruno Lapointe			Ajout du champs de date du dernier dépôt pour contrat et relevés de dépôts
								ADX0000594	IA	2004-11-24	Bruno Lapointe			Gestion du log
								ADX0000578	IA	2004-11-25	Bruno Lapointe			400 expédié en même temps que les 100 et 200
								ADX0001177	BR	2004-12-01	Bruno Lapointe			Changement des codes d'erreurs et des validations
								ADX0000612	IA	2005-01-03	Bruno Lapointe			Gestion de l'historique des années de qualification
								ADX0001221	BR	2005-01-07	Bruno Lapointe			Correction de bug dans le log de modification
								ADX0001323	BR	2005-03-09	Bruno Lapointe			L'historique d'année de qualification n'était pas créé lors d'insertion de convention.
								ADX0000670	IA	2005-03-14	Bruno Lapointe			Suppression du champ LastDepositForDoc
								ADX0000691	IA	2005-05-06	Bruno Lapointe			Envoi automatique de la lettre d'émission au tuteur sur premier CPA ou PRD.
								ADX0000828	IA	2006-06-15	Alain Quirion			Ajout d'un paramètre d'Entr‚e DiplomaTexT afin de permettre l'ajout d'un texte pour diplôme si DiplomaTextID = -1
								ADX0001337	IA	2007-06-04	Bruno Lapointe			Calcul automatique de l'année de qualification.
								ADX0001355	IA	2007-06-06	Alain Quirion			Utilisation de dtRegEndDateAdjust en remplacement de RegEndDateAddyear
												2008-06-10  Nassim Rekkab			ajout de Conditions 1ere Condition :ConventionID = 0 et ConventionNo contient une lettre 
																					donc formater le ConventionNo selon :ConventionNo + PmtDate (avec 8 chiffres yyyymmdd)
																					2eme condition :ConventionNo est null ou vide donc laisser le traitement comme presentement (prendre la date du jour)
												2008-09-15  Radu Trandafir			Ajout du champ DestinationRemboursement
																					Ajout du champ DestinationRemboursementAutre
																					Ajout du champ DateduProspectus	
																					Ajout du champ SouscripteurDesireIQEE
																					Ajout du champ LienCoSouscripteur
												2008-12-17	Éric Deshaies			Ajout d'un historique des changements de bénéficiaire: Ajout
																					d'un premier élément à l'historique lors de la création d'une
																					nouvelle convention.
												2009-04-09	Donald Huppé			Correction d'un bug qui générait un NULL dans CRQ_Log.LogText : ajout de ISNULL() aux endroits indiqués par "2009-04-09"
																					Ce bug faisait planter SP_SL_CRQ_LogOfObject 
												2009-06-16	Patrick Robitaille		Ajout du champ bTuteur_Desire_Releve_Elect
												2009-08-06	Jean-François Gauthier	Ajout du champ iSous_Cat_ID_Resp_Prelevement
												2009-11-24	Jean-François Gauthier	Modification pour les remboursements éventuels suite à un changement de bénéficiaire
												2009-12-02	Jean-François Gauthier	Modification pour le changement de bénéficiaires
												2010-01-07	Pierre-Luc Simard		Ajout du régime Reeeflex 2010
												2010-01-28	Pierre Paquet			Ajustement sur le call de IU_UN_OperBNA. 
												2010-02-22	Jean-François Gauthier	Modification pour éliminer les cotisations NULL du curseur curBlob
												2010-02-23	Pierre Paquet			Ajout des automatismes pour les cases reliées au projet 'Formulaire RHDSC'
												2010-03-01	Pierre Paquet			Correction du bogue dans IU_UN_ReversedCESP400
												2010-03-02	Jean-François Gauthier	Traitement des transactions FCB-RCB dans le cas d'un changement de bénéficiaire
												2010-03-03	Pierre Paquet			Correction de IF (@vcLigneBlobCotisation <> '')
												2010-03-03	Jean-François Gauthier	Correction d'un problème avec la table temporaire #PropNo
												2010-03-09	Jean-François Gauthier	Correction d'un problème de formatage du BLOB des cotisations
												2010-03-19	Jean-François Gauthier	Ajout du critère sur le ConventionID lors du traitement d'un cas de décès ("DEC")
												2010-04-29	Pierre Paquet			Correction: Situation #3 de remboursement au PCEE.
																					Correction: ajout du type d'oper dans  le blob.
												2010-04-29  Jean-François Gauthier	Ajout du paramètre @bSansVerificationPCEE400 lors de l'appel à IU_UN_ReSendCotisationCESP400
												2010-04-30	Pierre Paquet			Correction: Ajustement aux condition1 et condition2. pour le remboursement situation 3.
												2010-05-17	Pierre Paqdbuet			Correction: Il manquait le paramètre @ConnectID pour le call de IU_UN_ResendCotisationCESP400.
												2010-05-18	Pierre Paquet			Correction: Utilisation de Effectdate plutôt que OperDate pour le cas 'DEC'.
												2010-05-20	Jean-François Gauthier	Ajustement de la validation du bénéficiaire cédant (modification initiale du 2010-03-02)
												2010-05-21	Pierre Paquet			Correction: Sauvegarder bFormulaireRecu dans UN_Convention.
												2010-05-25	Pierre Paquet			MISE en commentaire de la gestion automatique de FCB le temps des tests.
												2010-05-31	Pierre Paquet			FCB: Ajout de la vérification de la présence du NAS du bénéf et du souscripteur.
												2010-06-02	Pierre Paquet			Correction: Initialisation à 1 de @iResult.
																					Correction: Utilisation du bon NAS pour la création du 400-11 (chang. bénéf).
																					Correction: Mise à jour du tiCESPState de la convention.
												2010-06-04	Pierre Paquet			Correction: Lien avec le nouveau bénéf pour le NAS.
																					Correction: Vérifier s'il y a un montant SCEE ou SCEE+ pour caller IU_UN_OperBNA.
												2010-09-07	Pierre Paquet			Ajustement au niveau de la suppression des 400-11, il faut updater plutôt.
												2010-10-18	Pierre Paquet			Ajustement à un FETCH..il manquait un argument.
												2011-01-31	Frederick Thibault		Ajout du champ fACESGPart pour régler le problème SCEE+
												2011-06-03	Donald Huppé			Au changement de bénéficiaire, correction de la vérification de la Situation 2. La vérification de l'âge 21 ans était mal calculée.
												2011-06-07	Frederick Thibault		Fait passé de 3 à 4 chiffre le no. séquentiel dans les cas où on dépasse 999 (FT1)
												2011-10-28	Christian Chénard		Ajout du champ vcCommInstrSpec dans l'enregistrement d'une convention
												2011-11-08	Christian Chénard		Ajout du champ iID_Justification_Conv_Incomplete								
												2014-11-07	Pierre-Luc Simard		Ne plus enregistrer la valeur des champs tiCESPState, et CESGRequest qui sont maintenant gérés par la 
																									procédure psCONV_EnregistrerPrevalidationPCEE, en édition. 
																									À la création, si la case SCEEFormulaire93Recu sera mise à jour à partir du paramètre bFormulaireRecu. 
																									La case bFormulaireRecu sera enregistré à zéro et ensuit emodifié par la procédure psCONV_EnregistrerPrevalidationPCEE.
												2015-02-03	Pierre-Luc Simard		Ne plus gérer les changements de case Formulaire reçu puisque gérés via la procédure psCONV_EnregistrerPrevalidationPCEE.
												2015-07-29	Steve Picard				Utilisation du "Un_Convention.TexteDiplome" au lieu de la table UN_DiplomaText
												2015-09-04	Pierre-Luc Simard		Ne plus générer de lettre Tuteur lors d'un changement de bénéficiaire
                                                2018-10-29  Pierre-Luc Simard       Utilisation du champ cLettre_PrefixeConventionNo

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_Convention] (
	@ConnectID			INT,
	@ConventionID		INT,
	@SubscriberID		INT,
	@CoSubscriberID		INT,
	@BeneficiaryID		INT,
	@PlanID				INT,
	@ConventionNo		VARCHAR(15),
	@PmtDate			DATETIME,
	@PmtTypeID			VARCHAR(3),
	@GovernmentRegDate	DATETIME,
	@DiplomaTextID		INT = -1,				
	@bSendToCESP		BIT,				-- Champ boolean indiquant si la convention doit être envoyée au PCEE (1) ou non (0).
	@bCESGRequested		BIT,				-- SCEE voulue (1) ou non (2)
	@bACESGRequested	BIT,				-- SCEE+ voulue (1) ou non (2)
	@bCLBRequested		BIT,				-- BEC voulu (1) ou non (2)
	@tiCESPState		TINYINT,			-- État de la convention au niveau des pré-validations. (0 = Rien ne passe , 1 = Seul la SCEE passe, 2 = SCEE et BEC passe, 3 = SCEE et SCEE+ passe et 4 = SCEE, BEC et SCEE+ passe)
	@tiRelationshipTypeID	TINYINT,  		-- ID du lien de parenté entre le souscripteur et le bénéficiaire.
	@DiplomaText			VARCHAR(150),	-- Texte du diplòme
	@iDestinationRemboursementID		INT,
	@vcDestinationRemboursementAutre	VARCHAR(50),
	@dtDateduProspectus					DATETIME,
	@bSouscripteurDesireIQEE			BIT,
	@tiLienCoSouscripteur				TINYINT,
	@bTuteurDesireReleveElect			BIT,
	@iSous_Cat_ID_Resp_Prelevement		INT,
	@bFormulaireRecu					BIT = NULL)
--	@vcCommInstrSpec					varchar(150),
--	@iJustificationConvIncompleteID		INT = NULL)
AS
BEGIN
	DECLARE
		@bCarac											BIT	
		,@iPosition										INT
		,@cLettre										CHAR(1)
		,@iResult										INT
		,@iConventionNo3Last							INT
		,@iConventionID									INT
		-- Variable du caractère séparateur de valeur du blob
		,@iOldSubscriberID								INT
		,@iOldCoSubscriberID							INT
		,@iOldBeneficiaryID								INT
		,@iOldPlanID									INT
		,@vcOldConventionNo								VARCHAR(15)
		,@dtOldFirstPmtDate								DATETIME
		,@vcOldPmtTypeID								VARCHAR(3)
		,@dtOldGovernmentRegDate						DATETIME
		--,@iOldDiplomaTextID								INT = -1		-- 2015-07-29
		,@vcOldTexteDiplome								VARCHAR(max)
		,@bOldSendToCESP								BIT		-- Champ boolean indiquant si la convention doit être envoyée au PCEE (1) ou non (0).
		,@bOldFormulaireRecu							BIT
		,@vcOldCommInstrSpec							varchar(150)
		,@iOldJustificationConvIncompleteID				INT
		,@bOldCESGRequested								BIT		-- SCEE voulue (1) ou non (2)
		,@bOldACESGRequested							BIT		-- SCEE+ voulue (1) ou non (2)
		,@bOldCLBRequested								BIT		-- BEC voulu (1) ou non (2)
		,@tiOldCESPState								TINYINT	-- État de la convention au niveau des pré-validations. (0 = Rien ne passe , 1 = Seul la SCEE passe, 2 = SCEE et BEC passe, 3 = SCEE et SCEE+ passe et 4 = SCEE, BEC et SCEE+ passe)
		,@tiOldRelationshipTypeID						TINYINT -- ID du lien de parenté entre le souscripteur et le bénéficiaire.
		,@iOldDestinationRemboursementID				INT
		,@vcOldDestinationRemboursementAutre			VARCHAR(50)
		,@dtOldDateduProspectus							DATETIME
		,@bOldSouscripteurDesireIQEE					BIT
		,@tiOldLienCoSouscripteur						TINYINT
		,@bOldTuteurDesireReleveElect					BIT
		,@cSep											CHAR(1)
		,@dtDateConvention								DATETIME
		,@iOldSous_Cat_ID_Resp_Prelevement				INT
		,@bLien_Frere_Soeur_Avec_Ancien_Beneficiaire	BIT		-- Indique si le lien entre le nouveau bénéficiaire et l'ancien est de type "frère / soeur"
		,@mSCEE											MONEY
		,@mSCEESup										MONEY
		,@iIDBlob										INT		-- BLOB DES OPÉRATIONS
		,@iIDOper										INT
		,@vcLigneBlob									VARCHAR(MAX)
		,@dtOperDate									DATETIME
		,@bLien_Sang_Avec_Souscripteur_Initial			BIT
		,@vcCodeRaisonChangement						VARCHAR(3)
		,@dtDate_Changement_Beneficiaire				DATETIME
		,@iIDCotisationBlob								INT		-- BLOB DES COTISATIONS
		,@vcLigneBlobCotisation							VARCHAR(MAX)
		,@iCompteLigne									INT
		,@iIDOperCur									INT
		,@iIDCotisationCur								INT
		,@dtDateOperCur									DATETIME
		,@iID_OperARenverser							INT
		,@iID_CotisationARenverser						INT
		,@iID_OperTypeBlob								CHAR(3)
		,@ageNouveauBeneficiaire						INT
		,@ageAncienBeneficiaire							INT
		,@cOperTypeID									CHAR(3)
		,@bSansVerificationPCEE400						INT  -- 2010-04-29 : JFG : Ajout
		,@bNouvelleConvention							TINYINT -- Indique si c'est une nouvelle convention. (BEC)
		,@tiCESPState_B									TINYINT -- État du bénéficiaire 
		,@tiCESPState_S									TINYINT -- État du souscripteur.
		,@iCode_Retour										INT		
		,@cAncienEtatConvention						VARCHAR(3) -- Ancien état de la convention		

	SET @cSep = CHAR(30)
	SET @bSansVerificationPCEE400 = 1 -- 2010-04-29 : JFG : Ajout
	SET @bNouvelleConvention = 0

	-----------------
	BEGIN TRANSACTION
	-----------------
	SELECT
		@iOldSubscriberID = SubscriberID,
		@iOldCoSubscriberID = CoSubscriberID,
		@iOldBeneficiaryID = BeneficiaryID,
		@iOldPlanID = PlanID,
		@vcOldConventionNo = ConventionNo,
		@dtOldFirstPmtDate = FirstPmtDate,
		@vcOldPmtTypeID = PmtTypeID,
		@dtOldGovernmentRegDate = GovernmentRegDate,
		@bOldFormulaireRecu = bFormulaireRecu,
		@vcOldCommInstrSpec = vcCommInstrSpec,
		@iOldJustificationConvIncompleteID = iID_Justification_Conv_Incomplete,
		@bOldSendToCESP = bSendToCESP,
		@bOldCESGRequested = bCESGRequested,
		@bOldACESGRequested = bACESGRequested,
		@bOldCLBRequested = bCLBRequested,
		@tiOldCESPState = tiCESPState,
		@tiOldRelationshipTypeID = tiRelationshipTypeID,
		--@iOldDiplomaTextID = IsNull(DiplomaTextID, 0),	-- 2015-07-29
		@vcOldTexteDiplome = IsNull(TexteDiplome, ''),
		@iOldDestinationRemboursementID = iID_Destinataire_Remboursement,
		@vcOldDestinationRemboursementAutre = vcDestinataire_Remboursement_Autre,
		@dtOldDateduProspectus = dtDateProspectus,
		@bOldSouscripteurDesireIQEE = bSouscripteur_Desire_IQEE,
		@tiOldLienCoSouscripteur = tiID_Lien_CoSouscripteur,
		@bOldTuteurDesireReleveElect = bTuteur_Desire_Releve_Elect,
		@iOldSous_Cat_ID_Resp_Prelevement = iSous_Cat_ID_Resp_Prelevement
	FROM dbo.Un_Convention 
	WHERE ConventionID = @ConventionID
	  AND (	@ConventionID > 0 
			)

	-- Met des valeurs à NULL si elle sont plus petite ou égal à 0
	IF @CoSubscriberID <= 0 
		SET @CoSubscriberID = NULL

	IF @GovernmentRegDate <= 0
		SET @GovernmentRegDate = NULL

	IF @DiplomaTextID > 0		-- 2015-07-29
		SELECT @DiplomaText = DiplomaText FROM dbo.Un_Diplomatext
		WHERE DiplomaTextID = @DiplomaTextID
	-- ID du diplome = NULL si 0, Création si -1
	IF @DiplomaTextID = 0			-- Aucun texte de diplôme
		SELECT @DiplomaTextID = NULL,
			   @DiplomaText = NULL
	/*	2015-07-29
	IF @DiplomaTextID = -1		-- Texte de diplôme personnalisé
	BEGIN
		INSERT INTO Un_DiplomaText(DiplomaText, VisibleInList)
		VALUES(@DiplomaText, 0)

		IF @@ERROR = 0
			SET @DiplomaTextID = SCOPE_IDENTITY()
		ELSE
			SET @DiplomaTextID = NULL		-- NULL si l'insertion n'a pas foncitonné
	END */

	--Vérifie si la convention existe
	IF (@ConventionID = 0)
	BEGIN

		-- Indique que c'est une nouvelle convention.
		SET @bNouvelleConvention = 1

		--assigne la date reçu en paramètre, sinon la date du jour
		SET @dtDateConvention = ISNULL(@PmtDate,GETDATE())

		-- Initialiser les variables
		SET @iPosition = 1
		SET @bCarac = 0
		--Boucle pour tester l'existence de caracteres au niveau du @ConventionNo
		WHILE (@iPosition <= LEN(@ConventionNo) AND @bCarac=0) 
		BEGIN
			IF(ASCII(SUBSTRING(@ConventionNo,@iPosition,1)) NOT BETWEEN 48 AND 57)
				BEGIN
					SET @cLettre = SUBSTRING(@ConventionNo,@iPosition,1)
					SET @ConventionNo = @cLettre +'-'+ CONVERT(VARCHAR (8),(@dtDateConvention),112) -- Nassim: permet de formater le numero de Convention selon 1er Caractere trouve + Date Pmt en format de 8 chiffre (yyyymmdd)
					SET @bCarac = 1
				END
			SET @iPosition = @iPosition +1
		END

		--si on n'a pas trouvé de caractères, on le crée comme avant
		IF (@bCarac = 0)
		BEGIN

			SET @dtDateConvention = GETDATE()

            SELECT 
                @ConventionNo = ISNULL(P.cLettre_PrefixeConventionNo, '') + '-' + CAST(YEAR(@dtDateConvention) AS CHAR(4)) 
            FROM Un_Plan P
            WHERE P.PlanID = @PlanID
            /*
			IF @PlanID = 4
				SET @ConventionNo = 'I-' + CAST(YEAR(@dtDateConvention) AS CHAR(4))
			ELSE IF @PlanID = 8
				SET @ConventionNo = 'U-' + CAST(YEAR(@dtDateConvention) AS CHAR(4))
			ELSE IF @PlanID = 10
				SET @ConventionNo = 'R-' + CAST(YEAR(@dtDateConvention) AS CHAR(4))
			ELSE IF @PlanID = 11
				SET @ConventionNo = 'B-' + CAST(YEAR(@dtDateConvention) AS CHAR(4))
			ELSE IF @PlanID = 12
				SET @ConventionNo = 'X-' + CAST(YEAR(@dtDateConvention) AS CHAR(4))
            */
			IF MONTH(@dtDateConvention) > = 10
				SET @ConventionNo = @ConventionNo + CAST(MONTH(@dtDateConvention) AS  CHAR(2))
			ELSE
				SET @ConventionNo = @ConventionNo + '0' + CAST(MONTH(@dtDateConvention) AS  CHAR(1))

			IF DAY(@dtDateConvention) > = 10
				SET @ConventionNo = @ConventionNo + CAST(DAY(@dtDateConvention) AS  CHAR(2))
			ELSE
				SET @ConventionNo = @ConventionNo + '0' + CAST(DAY(@dtDateConvention) AS  CHAR(1))

		END

		-- FT1
		----ajout du numéro séquentiel		
		--SELECT 
		--	@iConventionNo3Last = CAST(SUBSTRING(ISNULL(MAX(ConventionNo), @ConventionNo + '000'), 11, 3) AS INT) + 1
		--FROM dbo.Un_Convention 
		--WHERE ConventionNo LIKE (@ConventionNo + '%')

		--IF @iConventionNo3Last < 10
		--	SET @ConventionNo = @ConventionNo + '00' + CAST(@iConventionNo3Last AS  CHAR(1))
		--ELSE IF @iConventionNo3Last < 100
		--	SET @ConventionNo = @ConventionNo + '0' + CAST(@iConventionNo3Last AS  CHAR(2))
		--ELSE
		--	SET @ConventionNo = @ConventionNo + CAST(@iConventionNo3Last AS  CHAR(3))
		SELECT @iConventionNo3Last = COUNT(1) + 1
		FROM dbo.Un_Convention 
		WHERE ConventionNo LIKE (@ConventionNo + '%')

		DECLARE @ConventionNoTemp VARCHAR(15)

		IF @iConventionNo3Last > 999
			SET @ConventionNoTemp = @ConventionNo + RIGHT('0000'+ CONVERT(VARCHAR, @iConventionNo3Last), 4)
		ELSE
			SET @ConventionNoTemp = @ConventionNo + RIGHT('000'+ CONVERT(VARCHAR, @iConventionNo3Last), 3)

		WHILE EXISTS (SELECT 1 FROM dbo.Un_Convention WHERE ConventionNo = @ConventionNoTemp)
			BEGIN

			SET @iConventionNo3Last = @iConventionNo3Last + 1

			IF @iConventionNo3Last > 999
				SET @ConventionNoTemp = @ConventionNo + RIGHT('0000'+ CONVERT(VARCHAR, @iConventionNo3Last), 4)
			ELSE
				SET @ConventionNoTemp = @ConventionNo + RIGHT('000'+ CONVERT(VARCHAR, @iConventionNo3Last), 3)

			END

		SET @ConventionNo = @ConventionNoTemp

		-- /FT1

		INSERT INTO dbo.Un_Convention (
				SubscriberID,
				BeneficiaryID,
				ConventionNo,
				FirstPmtDate,
				PmtTypeID,
				GovernmentRegDate,
				PlanID,
				dtRegEndDateAdjust,
				dtInforceDateTIN,
				CoSubscriberID,
				--DiplomaTextID,	-- 2015-07-29
				TexteDiplome,
				bSendToCESP,
				bCESGRequested,
				bACESGRequested,
				bCLBRequested,
				tiCESPState,
				tiRelationshipTypeID,
				InsertConnectID,
				iID_Destinataire_Remboursement,
				dtDateProspectus,
				vcDestinataire_Remboursement_Autre,
				bSouscripteur_Desire_IQEE,
				tiID_Lien_CoSouscripteur,
				bTuteur_Desire_Releve_Elect,
				iSous_Cat_ID_Resp_Prelevement,
				bFormulaireRecu,
				SCEEFormulaire93Recu)
--				vcCommInstrSpec,
--				iID_Justification_Conv_Incomplete)				
			VALUES (
				@SubscriberID,
				@BeneficiaryID,
				@ConventionNo,
				@PmtDate,
				@PmtTypeID,
				@GovernmentRegDate,
				@PlanID,
				NULL,
				NULL,
				@CoSubscriberID,
				--@DiplomaTextID,	-- 2015-07-29
				IsNull(@DiplomaText, ''),
				@bSendToCESP,
				0, --@bCESGRequested,
				0, --@bACESGRequested,
				0, --@bCLBRequested,
				0, --@tiCESPState,
				@tiRelationshipTypeID,
				@ConnectID,
				@iDestinationRemboursementID,
				@dtDateduProspectus,
				@vcDestinationRemboursementAutre,		
				@bSouscripteurDesireIQEE,
				@tiLienCoSouscripteur,
				@bTuteurDesireReleveElect,
				@iSous_Cat_ID_Resp_Prelevement,
				0, --@bFormulaireRecu
				@bFormulaireRecu--SCEEFormulaire93Recu
				)
--				@vcCommInstrSpec,
--				@iJustificationConvIncompleteID)		

		IF @@ERROR = 0
			SET @ConventionID = SCOPE_IDENTITY()
		ELSE
			SET @ConventionID = -1		

		-- Mettre à jour l'état des prévalidations et les CESRequest de la convention
		EXEC @iCode_Retour = psCONV_EnregistrerPrevalidationPCEE @ConnectID, @ConventionID, NULL, NULL, NULL

		IF @iCode_Retour <= 0 
				SET @ConventionID = -1

		SELECT
			@tiCESPState = tiCESPState,
			@bFormulaireRecu = bFormulaireRecu,
			@bCESGRequested = bCESGRequested,
			@bACESGRequested = bACESGRequested,
			@bCLBRequested = bCLBRequested
		FROM dbo.Un_Convention C
		WHERE C.ConventionID = @ConventionID

		-- Ajout d'un historique des changements de bénéficiaire: Ajout
		-- d'un premier élément à l'historique lors de la création d'une
		-- nouvelle convention.
		IF @ConventionID > 0
			BEGIN
				DECLARE 
						@iID_Utilisateur_Creation INT,
						@tiID_Type_Relation_Souscripteur TINYINT

				SELECT @iID_Utilisateur_Creation = UserID
				FROM Mo_Connect C
				WHERE C.ConnectID = @ConnectID

				IF @tiRelationshipTypeID IN (1,2,4)
					SET @tiID_Type_Relation_Souscripteur = 1
				ELSE
					SET @tiID_Type_Relation_Souscripteur = 0

				EXEC @iCode_Retour = [dbo].[psCONV_AjouterChangementBeneficiaire] @ConventionID, @BeneficiaryID, 'INI', NULL, NULL, @tiID_Type_Relation_Souscripteur, @tiRelationshipTypeID, @tiLienCoSouscripteur, @iID_Utilisateur_Creation

				IF @@ERROR <> 0 OR @iCode_Retour < 0
					SET @ConventionID = -6
			END

		IF @ConventionID > 0
		BEGIN
			-- Insère un log de l'objet inséré.
			INSERT INTO CRQ_Log (
				ConnectID,
				LogTableName,
				LogCodeID,
				LogTime,
				LogActionID,
				LogDesc,
				LogText)
				SELECT
					@ConnectID,
					'Un_Convention',
					@ConventionID,
					GETDATE(),
					LA.LogActionID,
					LogDesc = 'Convention : '+C.ConventionNo,
					LogText =
						'SubscriberID'+@cSep+CAST(C.SubscriberID AS VARCHAR)+@cSep+ISNULL(S.LastName+', '+S.FirstName,'')+@cSep+CHAR(13)+CHAR(10)+
						CASE 
							WHEN ISNULL(C.CoSubscriberID,0) <= 0 THEN ''
						ELSE 'CoSubscriberID'+@cSep+CAST(C.CoSubscriberID AS VARCHAR)+@cSep+ISNULL(CS.LastName+', '+CS.FirstName,'')+@cSep+CHAR(13)+CHAR(10)
						END+
						'BeneficiaryID'+@cSep+CAST(C.BeneficiaryID AS VARCHAR)+@cSep+ISNULL(B.LastName+', '+B.FirstName,'')+@cSep+CHAR(13)+CHAR(10)+
						'PlanID'+@cSep+CAST(C.PlanID AS VARCHAR)+@cSep+ISNULL(P.PlanDesc,'')+@cSep+CHAR(13)+CHAR(10)+
						'ConventionNo'+@cSep+C.ConventionNo+@cSep+CHAR(13)+CHAR(10)+
						'FirstPmtDate'+@cSep+CONVERT(CHAR(10), C.FirstPmtDate, 20)+@cSep+CHAR(13)+CHAR(10)+
						'PmtTypeID'+@cSep+C.PmtTypeID+@cSep+
						CASE C.PmtTypeID
							WHEN 'AUT' THEN 'Automatique'
							WHEN 'CHQ' THEN 'Chèque'
						ELSE ''
						END+@cSep+
						CHAR(13)+CHAR(10)+
						'tiRelationshipTypeID'+@cSep+CAST(C.tiRelationshipTypeID AS VARCHAR)+@cSep+
						CASE C.tiRelationshipTypeID
							WHEN 1 THEN 'Père/Mère'
							WHEN 2 THEN 'Grand-père/Grand-mère'
							WHEN 3 THEN 'Oncle/Tante'
							WHEN 4 THEN 'Frère/Soeur'
							WHEN 5 THEN 'Aucun lien de parenté'
							WHEN 6 THEN 'Autre'
							WHEN 7 THEN 'Organisme'
						ELSE ''
						END+@cSep+
						CHAR(13)+CHAR(10)+
						CASE 
							WHEN ISNULL(C.GovernmentRegDate,0) <= 0 THEN ''
						ELSE 'GovernmentRegDate'+@cSep+CONVERT(CHAR(10), C.GovernmentRegDate, 20)+@cSep+CHAR(13)+CHAR(10)
						END+
						CASE 
							WHEN ISNULL(C.TexteDiplome, '') = '' THEN ''
							ELSE 'TexteDiplome'+@cSep+C.TexteDiplome+@cSep+CHAR(13)+CHAR(10)
						END+
						'bSendToCESP'+@cSep+CAST(ISNULL(C.bSendToCESP,1) AS VARCHAR)+@cSep+
						CASE 
							WHEN ISNULL(C.bSendToCESP,1) = 0 THEN 'Non'
						ELSE 'Oui'
						END+@cSep+
						CHAR(13)+CHAR(10)+
						/*'bCESGRequested'+@cSep+CAST(ISNULL(C.bCESGRequested,1) AS VARCHAR)+@cSep+
						CASE 
							WHEN ISNULL(C.bCESGRequested,1) = 0 THEN 'Non'
						ELSE 'Oui'
						END+@cSep+
						CHAR(13)+CHAR(10)+
						'bACESGRequested'+@cSep+CAST(ISNULL(C.bACESGRequested,1) AS VARCHAR)+@cSep+
						CASE 
							WHEN ISNULL(C.bACESGRequested,1) = 0 THEN 'Non'
						ELSE 'Oui'
						END+@cSep+
						CHAR(13)+CHAR(10)+
						'bCLBRequested'+@cSep+CAST(ISNULL(C.bCLBRequested,1) AS VARCHAR)+@cSep+
						CASE 
							WHEN ISNULL(C.bCLBRequested,1) = 0 THEN 'Non'
						ELSE 'Oui'
						END+@cSep+
						CHAR(13)+CHAR(10)+
						'tiCESPState'+@cSep+CAST(ISNULL(C.tiCESPState,0) AS VARCHAR)+@cSep+
						CASE ISNULL(C.tiCESPState,0)
							WHEN 1 THEN 'SCEE'
							WHEN 2 THEN 'SCEE et BEC'
							WHEN 3 THEN 'SCEE et SCEE+'
							WHEN 4 THEN 'SCEE, SCEE+ et BEC'
						ELSE ''
						END+@cSep+
						CHAR(13)+CHAR(10)+*/						
						CASE 
							WHEN ISNULL(C.iID_Destinataire_Remboursement,0) <= 0 THEN ''
						ELSE 'iID_Destinataire_Remboursement'+@cSep+CAST(ISNULL(C.iID_Destinataire_Remboursement,0) AS VARCHAR)+@cSep+
						CASE C.iID_Destinataire_Remboursement
							WHEN 1 THEN 'Souscripteur'
							WHEN 2 THEN 'Bénéficiaire'
							WHEN 3 THEN 'Autre'
						ELSE ''
						END+@cSep+
						CHAR(13)+CHAR(10)
						END+
						CASE 
							WHEN ISNULL(C.vcDestinataire_Remboursement_Autre,'') = '' THEN ''
						ELSE 'vcDestinataire_Remboursement_Autre'+@cSep+C.vcDestinataire_Remboursement_Autre+@cSep+CHAR(13)+CHAR(10)
						END+
						CASE 
							WHEN ISNULL(C.dtDateProspectus,0) <= 0 THEN ''
						ELSE 'dtDateProspectus'+@cSep+CONVERT(CHAR(10), C.dtDateProspectus, 20)+@cSep+CHAR(13)+CHAR(10)
						END+
						'bSouscripteur_Desire_IQEE'+@cSep+CAST(ISNULL(C.bSouscripteur_Desire_IQEE,1) AS VARCHAR)+@cSep+
						CASE 
							WHEN ISNULL(C.bSouscripteur_Desire_IQEE,1) = 0 THEN 'Non'
						ELSE 'Oui'
						END+@cSep+
						CHAR(13)+CHAR(10)+
						CASE 
							WHEN ISNULL(C.tiID_Lien_CoSouscripteur,0) <= 0 THEN ''
							ELSE 'tiID_Lien_CoSouscripteur'+@cSep+CAST(ISNULL(C.tiID_Lien_CoSouscripteur,0) AS VARCHAR)+@cSep+
								 CASE C.tiID_Lien_CoSouscripteur
									WHEN 1 THEN 'Père/Mère'
									WHEN 2 THEN 'Grand-père/Grand-mère'
									WHEN 3 THEN 'Oncle/Tante'
									WHEN 4 THEN 'Frère/Soeur'
									WHEN 5 THEN 'Aucun lien de parenté'
									WHEN 6 THEN 'Autre'
									WHEN 7 THEN 'Organisme'
									ELSE ''
								 END
							END+@cSep+
						CHAR(13)+CHAR(10)+
						'bTuteur_Desire_Releve_Elect'+@cSep+CAST(ISNULL(C.bTuteur_Desire_Releve_Elect,1) AS VARCHAR)+@cSep+
						CASE 
							WHEN ISNULL(C.bTuteur_Desire_Releve_Elect,1) = 0 THEN 'Non'
						ELSE 'Oui'
						END/*+@cSep+
						CHAR(13)+CHAR(10)+						
						CASE 
							WHEN ISNULL(C.iID_Justification_Conv_Incomplete,0) <= 0 THEN ''
						ELSE 'iID_Justification_Conv_Incomplete'+@cSep+CAST(ISNULL(C.iID_Justification_Conv_Incomplete,0) AS VARCHAR)+@cSep+
						CASE C.iID_Justification_Conv_Incomplete
							WHEN 1 THEN 'Transfert In'
						ELSE ''
						END+@cSep+
						CHAR(13)+CHAR(10)
						END*/
					FROM dbo.Un_Convention C
					JOIN dbo.Mo_Human S ON S.HumanID = C.SubscriberID
					LEFT JOIN dbo.Mo_Human CS ON CS.HumanID = C.CoSubscriberID
					JOIN dbo.Mo_Human B ON B.HumanID = C.BeneficiaryID
					JOIN CRQ_LogAction LA ON LA.LogActionShortName = 'I'
					JOIN Un_Plan P ON P.PlanID = C.PlanID
					--LEFT JOIN Un_DiplomaText DT ON DT.DiplomaTextID = C.DiplomaTextID	-- 2015-07-29
					WHERE C.ConventionID = @ConventionID

			IF @@ERROR <> 0
				SET @ConventionID = -2
		END
	END
	ELSE 
	BEGIN

		SELECT @cAncienEtatConvention = dbo.fnCONV_ObtenirStatutConventionEnDate (@ConventionID, GETDATE())

		UPDATE c
			SET
				c.SubscriberID							= @SubscriberID
				,c.BeneficiaryID						= @BeneficiaryID
				,c.ConventionNo							= @ConventionNo
				,c.FirstPmtDate							= @PmtDate
				,c.PmtTypeID							= @PmtTypeID
				,c.PlanID								= @PlanID
				,c.GovernmentRegDate					= @GovernmentRegDate
				,c.CoSubscriberID						= @CoSubscriberID
				--,c.DiplomaTextID						= @DiplomaTextID	-- 2015-07-29
				,c.texteDiplome							= IsNull(@DiplomaText, '')
				,c.bSendToCESP							= @bSendToCESP
				--,c.bCESGRequested						= @bCESGRequested
				--,c.bACESGRequested						= @bACESGRequested
				--,c.bCLBRequested						= @bCLBRequested
				--,c.tiCESPState							= @tiCESPState
				,c.tiRelationshipTypeID					= @tiRelationshipTypeID
				,c.LastUpdateConnectID					= @ConnectID
				,c.iID_Destinataire_Remboursement		= @iDestinationRemboursementID
				,c.dtDateProspectus						= @dtDateduProspectus
				,c.vcDestinataire_Remboursement_Autre	= @vcDestinationRemboursementAutre
				,c.bSouscripteur_Desire_IQEE			= @bSouscripteurDesireIQEE
				,c.tiID_Lien_CoSouscripteur				= @tiLienCoSouscripteur
				,c.bTuteur_Desire_Releve_Elect			= @bTuteurDesireReleveElect
				,c.iSous_Cat_ID_Resp_Prelevement		= @iSous_Cat_ID_Resp_Prelevement
				--,c.bFormulaireRecu						= ISNULL(@bFormulaireRecu, c.bFormulaireRecu)
--				,c.vcCommInstrSpec						= @vcCommInstrSpec
--				,c.iID_Justification_Conv_Incomplete	= @iJustificationConvIncompleteID
		FROM
			dbo.Un_Convention c
		WHERE 
			c.ConventionID = @ConventionID

		IF @@ERROR <> 0
			SET @ConventionID = -3

		-- Mettre à jour l'état des prévalidations et les CESRequest de la convention
		EXEC @iCode_Retour = psCONV_EnregistrerPrevalidationPCEE @ConnectID, @ConventionID, NULL, NULL, NULL

		IF @iCode_Retour <= 0 
				SET @ConventionID = -3

		SELECT
			@tiCESPState = tiCESPState,
			@bFormulaireRecu = bFormulaireRecu,
			@bCESGRequested = bCESGRequested,
			@bACESGRequested = bACESGRequested,
			@bCLBRequested = bCLBRequested
		FROM dbo.Un_Convention C
		WHERE C.ConventionID = @ConventionID

		-- 2009-12-02 : JFG : Ajout de validation pour la gestion des changements de bénéficiaires

		-- Vérifier s'il y a un changement de bénéficiaire ---------------------------------------------------------------
		IF @BeneficiaryID <> @iOldBeneficiaryID
			BEGIN
				-- 2010-03-02 : JFG : Si le NAS du bénéficiaire cédant n'est pas présent mais que le nouveau bénéf a un NAS.
				--						- Calculer le montant des cotisations et des frais avec le changement
				--						- Créer une transaction RCB et une cotisation négative des montants calculés
				--						- Créer une transaction FCB et une cotisation positive des montants calculés
				--						- Créer une transaction 400-11 de demande de subvention

				IF	EXISTS(SELECT 1 FROM dbo.Mo_Human WHERE HumanID = @iOldBeneficiaryID AND NULLIF(LTRIM(RTRIM(SocialNumber)),'') IS NULL)
					AND EXISTS (SELECT 1 FROM dbo.Mo_Human WHERE HumanID = @BeneficiaryID AND SocialNumber IS NOT NULL AND SocialNumber <> '')
					AND EXISTS (SELECT 1 FROM dbo.Mo_Human WHERE HumanID = @SubscriberID AND SocialNumber IS NOT NULL AND SocialNumber <> '')
					AND (@cAncienEtatConvention = 'TRA')
					BEGIN
						DECLARE 
							@OperID INTEGER,
							@UnitID INTEGER,
							@Cotisation MONEY,
							@Fee MONEY		

						DECLARE curCotisation CURSOR FOR
							SELECT 
								U.UnitID,
								Cotisation = SUM(Ct.Cotisation),
								Fee = SUM(Ct.Fee)
							FROM dbo.Un_Unit U 
							JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
							JOIN Un_Oper O ON O.OperID = Ct.OperID
							WHERE O.OperDate < GETDATE()
							AND U.ConventionID = @ConventionID
							GROUP BY U.UnitID
							HAVING (SUM(Ct.Cotisation) <> 0)
								OR (SUM(Ct.Fee) <> 0)

						OPEN curCotisation
						SET @iResult = 1
						FETCH NEXT FROM curCotisation INTO 	@UnitID, @Cotisation, @Fee
						WHILE @@FETCH_STATUS = 0 AND @iResult > 0
							BEGIN
								INSERT INTO dbo.Un_Oper (
									ConnectID,
									OperTypeID,
									OperDate)
								VALUES (
									@ConnectID,
									'RCB',
									GETDATE())

								IF @@ERROR = 0
									SELECT @OperID = SCOPE_IDENTITY()
								ELSE
									SET @iResult = -7

								IF @iResult > 0
								BEGIN
									INSERT INTO dbo.Un_Cotisation (
										OperID,
										UnitID,
										EffectDate,
										Cotisation,
										Fee,
										BenefInsur,
										SubscInsur,
										TaxOnInsur)
									VALUES (
										@OperID,
										@UnitID,
										GETDATE(),
										-@Cotisation,
										-@Fee,
										0,
										0,
										0)

									IF @@ERROR <> 0
										SET @iResult = -8
								END

								IF @iResult > 0
								BEGIN
									INSERT INTO dbo.Un_Oper (
										ConnectID,
										OperTypeID,
										OperDate)
									VALUES (
										@ConnectID,
										'FCB',
										GETDATE())

									IF @@ERROR = 0
										SELECT @OperID = SCOPE_IDENTITY()
									ELSE
										SET @iResult = -9
								END

								IF @iResult > 0
								BEGIN
									INSERT INTO dbo.Un_Cotisation (
										OperID,
										UnitID,
										EffectDate,
										Cotisation,
										Fee,
										BenefInsur,
										SubscInsur,
										TaxOnInsur)
									VALUES (
										@OperID,
										@UnitID,
										GETDATE(),
										@Cotisation,
										@Fee,
										0,
										0,
										0)

									IF @@ERROR <> 0
										SET @iResult = -10
								END

								-- Crée l'enregistrement 400 de demande de subvention au PCEE.
								IF @iResult > 0
								BEGIN
									INSERT INTO dbo.Un_CESP400
											(
											 iCESPSendFileID
											,OperID
											,CotisationID
											,ConventionID
											,iCESP800ID
											,iReversedCESP400ID
											,tiCESP400TypeID
											,tiCESP400WithdrawReasonID
											,vcTransID
											,dtTransaction
											,iPlanGovRegNumber
											,ConventionNo
											,vcSubscriberSINorEN
											,vcBeneficiarySIN
											,fCotisation
											,bCESPDemand
											,dtStudyStart
											,tiStudyYearWeek
											,fCESG
											,fACESGPart
											,fEAPCESG
											,fEAP
											,fPSECotisation
											,iOtherPlanGovRegNumber
											,vcOtherConventionNo
											,tiProgramLength
											,cCollegeTypeID
											,vcCollegeCode
											,siProgramYear
											,vcPCGSINorEN
											,vcPCGFirstName
											,vcPCGLastName
											,tiPCGType
											,fCLB
											,fEAPCLB
											,fPG
											,fEAPPG
											,vcPGProv
											)
										SELECT
											 NULL
											,Ct.OperID
											,Ct.CotisationID
											,C.ConventionID
											,NULL
											,NULL
											,11
											,NULL
											,'FIN'
											,Ct.EffectDate
											,P.PlanGovernmentRegNo
											,C.ConventionNo
											,HS.SocialNumber
											,HB.SocialNumber
											,Ct.Cotisation+Ct.Fee
											,C.bCESGRequested
											,NULL
											,NULL
											,0
											,0
											,0
											,0
											,0
											,NULL
											,NULL
											,NULL
											,NULL
											,NULL
											,NULL
											,B.vcPCGSINOrEN
											,B.vcPCGFirstName
											,B.vcPCGLastName
											,B.tiPCGType
											,0
											,0
											,0
											,0
											,NULL
										FROM 
											dbo.Un_Cotisation Ct
											INNER JOIN dbo.Un_Unit U 
												ON U.UnitID = Ct.UnitID
											INNER JOIN dbo.Un_Convention C 
												ON C.ConventionID = U.ConventionID
											INNER JOIN dbo.Un_Plan P 
												ON P.PlanID = C.PlanID
											INNER JOIN dbo.Un_Beneficiary B 
												--ON B.BeneficiaryID = C.BeneficiaryID
												  ON B.BeneficiaryID = @BeneficiaryID
											INNER JOIN dbo.Mo_Human HB 
												--ON HB.HumanID = B.BeneficiaryID
												ON HB.HumanID = @BeneficiaryID
											INNER JOIN dbo.Mo_Human HS 
												ON HS.HumanID = C.SubscriberID
										WHERE 
											Ct.OperID = @OperID

										IF @iResult > 0
										BEGIN
											-- Inscrit le vcTransID avec le ID FIN + <iCESP400ID>.
											UPDATE Un_CESP400
											SET vcTransID = 'FIN'+CAST(iCESP400ID AS VARCHAR(12))
											WHERE vcTransID = 'FIN' 

											IF @@ERROR <> 0
												SET @iResult = -15
										END					

								END  -- fin du INSERT 
						FETCH NEXT FROM curCotisation INTO 	@UnitID, @Cotisation, @Fee
					END -- fin du WHILE
					CLOSE curCotisation
					DEALLOCATE curCotisation

					--DROP TABLE #PropBefore
				END  -- fin du IF bénéficiaire cédant sans NAS

				/*
				-- Vérifier si le nouveau bénéficiaire a toutes les informations de son principal responsable	
				IF EXISTS(	SELECT 1 FROM	dbo.Un_Beneficiary b
							WHERE	b.BeneficiaryID = @BeneficiaryID AND vcPCGSINOrEn	IS NOT NULL 
									AND	vcPCGFirstName	IS NOT NULL AND	vcPCGLastName	IS NOT NULL
						 )
					BEGIN
						-- Mise à jour du Formulaire reçu, du SCEE et du SCEE+
						SELECT
							@bFormulaireRecu	= 1
							,@bCESGRequested	= 1
							,@bACESGRequested	= 1
					END					
				ELSE
					BEGIN
						-- Mise à jour du Formulaire reçu et du SCEE
						SELECT
							@bFormulaireRecu	= 1
							,@bCESGRequested	= 1
							,@bACESGRequested	= 0
					END

				-- Il faut évaluer le tiCESPState avant la mise à jour. 2010-06-03 PPA.
				SET @tiCESPState_B = (SELECT tiCESPState FROM dbo.UN_Beneficiary WHERE BeneficiaryID = @BeneficiaryID)
				SET @tiCESPState_S = (SELECT tiCESPState FROM dbo.UN_Subscriber WHERE SubscriberID = @SubscriberID)
				IF (@tiCESPState_B = 0 OR @tiCESPState_S = 0)
				BEGIN
					SET @tiCESPState = 0
				END
				ELSE
				BEGIN
					SET @tiCESPState = @tiCESPState_B
				END
				*/

			END  -- fin du IF de changement de bénéficiaire.

		-- CRÉATION DU LOG
		IF EXISTS	(
				SELECT 
					ConventionID
				FROM dbo.Un_Convention 
				WHERE ConventionID = @ConventionID
					AND	(	@iOldSubscriberID <> SubscriberID
							OR	ISNULL(@iOldCoSubscriberID,0) <> ISNULL(CoSubscriberID,0)
							OR	@iOldBeneficiaryID <> BeneficiaryID
							OR @iOldPlanID <> PlanID
							OR @tiOldRelationshipTypeID <> tiRelationshipTypeID
							OR @vcOldPmtTypeID <> PmtTypeID
							OR @dtOldFirstPmtDate <> FirstPmtDate
							OR @bOldSendToCESP <> bSendToCESP
							--OR @bOldCESGRequested <> bCESGRequested
							--OR @bOldACESGRequested <> bACESGRequested
							--OR @bOldCLBRequested <> bCLBRequested
							--OR ISNULL(@iOldDiplomaTextID,0) <> ISNULL(DiplomaTextID,0)	-- 2015-07-29
							OR ISNULL(@vcOldTexteDiplome,'') <> ISNULL(TexteDiplome,'')
							OR ISNULL(@iOldDestinationRemboursementID,0) <> ISNULL(iID_Destinataire_Remboursement,0)
							OR ISNULL(@vcOldDestinationRemboursementAutre,'') <> ISNULL(vcDestinataire_Remboursement_Autre,'')
							OR ISNULL(@dtOldDateduProspectus,0) <> ISNULL(dtDateProspectus,0)
							OR ISNULL(@bOldSouscripteurDesireIQEE,0) <> ISNULL(bSouscripteur_Desire_IQEE,0)
							OR ISNULL(@tiOldLienCoSouscripteur,0) <> ISNULL(tiID_Lien_CoSouscripteur,0)
							OR ISNULL(@bOldTuteurDesireReleveElect,0) <> ISNULL(bTuteur_Desire_Releve_Elect,0)
							OR ISNULL(@iOldSous_Cat_ID_Resp_Prelevement,0) <> ISNULL(iSous_Cat_ID_Resp_Prelevement,0)
			--				OR ISNULL(@iJustificationConvIncompleteID,0) <> ISNULL(iID_Justification_Conv_Incomplete,0)
							)
						)
		AND @ConventionID > 0
		BEGIN
			-- Insère un log de l'objet modifié.
			INSERT INTO CRQ_Log (
				ConnectID,
				LogTableName,
				LogCodeID,
				LogTime,
				LogActionID,
				LogDesc,
				LogText)
				SELECT
					@ConnectID,
					'Un_Convention',
					@ConventionID,
					GETDATE(),
					LA.LogActionID,
					LogDesc = 'Convention : '+C.ConventionNo,
					LogText =
						CASE 
							WHEN @iOldSubscriberID <> C.SubscriberID THEN
								'SubscriberID'+@cSep+CAST(@iOldSubscriberID AS VARCHAR)+@cSep+CAST(C.SubscriberID AS VARCHAR)+@cSep+
								ISNULL(OS.LastName+', '+OS.FirstName,'')+@cSep+
								ISNULL(S.LastName+', '+S.FirstName,'')+@cSep+
								CHAR(13)+CHAR(10)
						ELSE ''
						END+
						CASE 
							WHEN ISNULL(@iOldCoSubscriberID,0) <> ISNULL(C.CoSubscriberID,0) THEN
								'CoSubscriberID'+@cSep+
								CASE 
									WHEN ISNULL(@iOldCoSubscriberID,0) = 0 THEN ''
								ELSE CAST(@iOldCoSubscriberID AS VARCHAR)
								END+@cSep+
								CASE 
									WHEN ISNULL(C.CoSubscriberID,0) = 0 THEN ''
								ELSE CAST(C.CoSubscriberID AS VARCHAR)
								END+@cSep+
								ISNULL(OCS.LastName+', '+OCS.FirstName,'')+@cSep+
								ISNULL(CS.LastName+', '+CS.FirstName,'')+@cSep+
								CHAR(13)+CHAR(10)
						ELSE ''
						END+
						CASE 
							WHEN @iOldBeneficiaryID <> C.BeneficiaryID THEN
								'BeneficiaryID'+@cSep+CAST(@iOldBeneficiaryID AS VARCHAR)+@cSep+CAST(C.BeneficiaryID AS VARCHAR)+@cSep+
								ISNULL(OB.LastName+', '+OB.FirstName,'')+@cSep+
								ISNULL(B.LastName+', '+B.FirstName,'')+@cSep+
								CHAR(13)+CHAR(10)
						ELSE ''
						END+
						CASE 
							WHEN @iOldPlanID <> C.PlanID THEN
								'PlanID'+@cSep+CAST(@iOldPlanID AS VARCHAR)+@cSep+CAST(C.PlanID AS VARCHAR)+@cSep+
								ISNULL(OP.PlanDesc,'')+@cSep+
								ISNULL(P.PlanDesc,'')+@cSep+
								CHAR(13)+CHAR(10)
						ELSE ''
						END+
						CASE 
							WHEN @tiOldRelationshipTypeID <> C.tiRelationshipTypeID THEN
								'tiRelationshipTypeID'+@cSep+CAST(@tiOldRelationshipTypeID AS VARCHAR)+@cSep+CAST(C.tiRelationshipTypeID AS VARCHAR)+@cSep+
								CASE @tiOldRelationshipTypeID
									WHEN 1 THEN 'Père/Mère'
									WHEN 2 THEN 'Grand-père/Grand-mère'
									WHEN 3 THEN 'Oncle/Tante'
									WHEN 4 THEN 'Frère/Soeur'
									WHEN 5 THEN 'Aucun lien de parenté'
									WHEN 6 THEN 'Autre'
									WHEN 7 THEN 'Organisme'
								ELSE ''
								END+@cSep+
								CASE C.tiRelationshipTypeID
									WHEN 1 THEN 'Père/Mère'
									WHEN 2 THEN 'Grand-père/Grand-mère'
									WHEN 3 THEN 'Oncle/Tante'
									WHEN 4 THEN 'Frère/Soeur'
									WHEN 5 THEN 'Aucun lien de parenté'
									WHEN 6 THEN 'Autre'
									WHEN 7 THEN 'Organisme'
								ELSE ''
								END+@cSep+
								CHAR(13)+CHAR(10)
						ELSE ''
						END+
						CASE 
							WHEN @vcOldPmtTypeID <> C.PmtTypeID THEN
								'PmtTypeID'+@cSep+@vcOldPmtTypeID+@cSep+C.PmtTypeID+@cSep+
								CASE @vcOldPmtTypeID
									WHEN 'AUT' THEN 'Automatique'
									WHEN 'CHQ' THEN 'Chèque'
								ELSE ''
								END+@cSep+
								CASE C.PmtTypeID
									WHEN 'AUT' THEN 'Automatique'
									WHEN 'CHQ' THEN 'Chèque'
								ELSE ''
								END+@cSep+
								CHAR(13)+CHAR(10)
						ELSE ''
						END+
						CASE 
							WHEN @dtOldFirstPmtDate <> C.FirstPmtDate THEN
								'FirstPmtDate'+@cSep+
								CONVERT(CHAR(10), @dtOldFirstPmtDate, 20)+@cSep+
								CONVERT(CHAR(10), C.FirstPmtDate, 20)+@cSep+
								CHAR(13)+CHAR(10)
						ELSE ''
						END+
						CASE 
							WHEN ISNULL(@bOldSendToCESP,1) <> ISNULL(C.bSendToCESP,0) THEN
								'bSendToCESP'+@cSep+
								CAST(ISNULL(@bOldSendToCESP,1) AS VARCHAR)+@cSep+
								CAST(ISNULL(C.bSendToCESP,1) AS VARCHAR)+@cSep+
								CASE 
									WHEN ISNULL(@bOldSendToCESP,1) = 0 THEN 'Non'
								ELSE 'Oui'
								END+@cSep+
								CASE 
									WHEN ISNULL(C.bSendToCESP,1) = 0 THEN 'Non'
								ELSE 'Oui'
								END+@cSep+
								CHAR(13)+CHAR(10)
						ELSE ''
						END+/*
						CASE 
							WHEN ISNULL(@bOldCESGRequested,1) <> ISNULL(C.bCESGRequested,0) THEN
								'bCESGRequested'+@cSep+
								CAST(ISNULL(@bOldCESGRequested,1) AS VARCHAR)+@cSep+
								CAST(ISNULL(C.bCESGRequested,1) AS VARCHAR)+@cSep+
								CASE 
									WHEN ISNULL(@bOldCESGRequested,1) = 0 THEN 'Non'
								ELSE 'Oui'
								END+@cSep+
								CASE 
									WHEN ISNULL(C.bCESGRequested,1) = 0 THEN 'Non'
								ELSE 'Oui'
								END+@cSep+
								CHAR(13)+CHAR(10)
						ELSE ''
						END+
						CASE 
							WHEN ISNULL(@bOldACESGRequested,1) <> ISNULL(C.bACESGRequested,0) THEN
								'bACESGRequested'+@cSep+
								CAST(ISNULL(@bOldACESGRequested,1) AS VARCHAR)+@cSep+
								CAST(ISNULL(C.bACESGRequested,1) AS VARCHAR)+@cSep+
								CASE 
									WHEN ISNULL(@bOldACESGRequested,1) = 0 THEN 'Non'
								ELSE 'Oui'
								END+@cSep+
								CASE 
									WHEN ISNULL(C.bACESGRequested,1) = 0 THEN 'Non'
								ELSE 'Oui'
								END+@cSep+
								CHAR(13)+CHAR(10)
						ELSE ''
						END+
						CASE 
							WHEN ISNULL(@bOldCLBRequested,1) <> ISNULL(C.bCLBRequested,0) THEN
								'bCLBRequested'+@cSep+
								CAST(ISNULL(@bOldCLBRequested,1) AS VARCHAR)+@cSep+
								CAST(ISNULL(C.bCLBRequested,1) AS VARCHAR)+@cSep+
								CASE 
									WHEN ISNULL(@bOldCLBRequested,1) = 0 THEN 'Non'
								ELSE 'Oui'
								END+@cSep+
								CASE 
									WHEN ISNULL(C.bCLBRequested,1) = 0 THEN 'Non'
								ELSE 'Oui'
								END+@cSep+
								CHAR(13)+CHAR(10)
						ELSE ''
						END+*/
						CASE 
							WHEN ISNULL(@vcOldTexteDiplome,'') <> ISNULL(C.TexteDiplome,'') THEN
								'TexteDiplome'+@cSep+
								ISNULL(@vcOldTexteDiplome,'')+@cSep+
								ISNULL(C.TexteDiplome,'')+@cSep+
								CHAR(13)+CHAR(10)
						ELSE ''
						END+
						CASE 
							WHEN ISNULL(@iOldDestinationRemboursementID,0) <> ISNULL(C.iID_Destinataire_Remboursement,0) THEN
																			-- 2009-04-07
								'iID_Destinataire_Remboursement'+@cSep+CAST(ISNULL(@iOldDestinationRemboursementID,0) AS VARCHAR)+@cSep+CAST(C.iID_Destinataire_Remboursement AS VARCHAR)+@cSep+
								CASE @iOldDestinationRemboursementID
									WHEN 1 THEN 'Souscripteur'
									WHEN 2 THEN 'Bénéficiaire'
									WHEn 3 THEN 'Autre'
								ELSE ''
								END+@cSep+
								CASE C.iID_Destinataire_Remboursement
									WHEN 1 THEN 'Souscripteur'
									WHEN 2 THEN 'Bénéficiaire'
									WHEn 3 THEN 'Autre'
								ELSE ''
								END+@cSep+
								CHAR(13)+CHAR(10)								
						ELSE ''
						END+
						CASE 
							WHEN ISNULL(@vcOldDestinationRemboursementAutre,'') <> ISNULL(C.vcDestinataire_Remboursement_Autre,'') THEN
								'vcDestinataire_Remboursement_Autre'+@cSep+
								CASE 
									WHEN ISNULL(@vcOldDestinationRemboursementAutre,'') = '' THEN ''
								ELSE @vcOldDestinationRemboursementAutre
								END+@cSep+
								CASE 
									WHEN ISNULL(C.vcDestinataire_Remboursement_Autre,'') = '' THEN ''
								ELSE C.vcDestinataire_Remboursement_Autre
								END+@cSep+CHAR(13)+CHAR(10)
						ELSE ''
						END+
						CASE 
							WHEN ISNULL(@dtOldDateduProspectus,0) <> ISNULL(C.dtDateProspectus,0) THEN
								'dtDateProspectus'+@cSep+
								CASE 
									WHEN ISNULL(@dtOldDateduProspectus,0) = 0 THEN ''
								ELSE CONVERT(CHAR(10), @dtOldDateduProspectus, 20)
								END+@cSep+
								CASE 
									WHEN ISNULL(C.dtDateProspectus,0) = 0 THEN ''
								ELSE CONVERT(CHAR(10), C.dtDateProspectus, 20)
								END+@cSep+CHAR(13)+CHAR(10)
						ELSE ''
						END+

						CASE 
							WHEN ISNULL(@bOldSouscripteurDesireIQEE,1) <> ISNULL(C.bSouscripteur_Desire_IQEE,0) THEN
								'bSouscripteur_Desire_IQEE'+@cSep+
								CAST(ISNULL(@bOldSouscripteurDesireIQEE,1) AS VARCHAR)+@cSep+
								CAST(ISNULL(C.bSouscripteur_Desire_IQEE,1) AS VARCHAR)+@cSep+
								CASE 
									WHEN ISNULL(@bOldSouscripteurDesireIQEE,1) = 0 THEN 'Non'
								ELSE 'Oui'
								END+@cSep+
								CASE 
									WHEN ISNULL(C.bSouscripteur_Desire_IQEE,1) = 0 THEN 'Non'
								ELSE 'Oui'
								END+@cSep+
								CHAR(13)+CHAR(10)
						ELSE ''
						END+
						CASE 
							WHEN ISNULL(@tiOldLienCoSouscripteur,0) <> ISNULL(C.tiID_Lien_CoSouscripteur,0) THEN
																	-- 2009-04-07
								'tiID_Lien_CoSouscripteur'+@cSep+CAST(ISNULL(@tiOldLienCoSouscripteur,0) AS VARCHAR)+@cSep+CAST(C.tiID_Lien_CoSouscripteur AS VARCHAR)+@cSep+
								CASE @tiOldLienCoSouscripteur
									WHEN 1 THEN 'Père/Mère'
									WHEN 2 THEN 'Grand-père/Grand-mère'
									WHEN 3 THEN 'Oncle/Tante'
									WHEN 4 THEN 'Frère/Soeur'
									WHEN 5 THEN 'Aucun lien de parenté'
									WHEN 6 THEN 'Autre'
									WHEN 7 THEN 'Organisme'
								ELSE ''
								END+@cSep+
								CASE C.tiID_Lien_CoSouscripteur
									WHEN 1 THEN 'Père/Mère'
									WHEN 2 THEN 'Grand-père/Grand-mère'
									WHEN 3 THEN 'Oncle/Tante'
									WHEN 4 THEN 'Frère/Soeur'
									WHEN 5 THEN 'Aucun lien de parenté'
									WHEN 6 THEN 'Autre'
									WHEN 7 THEN 'Organisme'
								ELSE ''
								END+@cSep+
								CHAR(13)+CHAR(10)
						ELSE ''
						END+
						CASE 
							WHEN ISNULL(@bOldTuteurDesireReleveElect,1) <> ISNULL(C.bTuteur_Desire_Releve_Elect,0) THEN
								'bSouscripteur_Desire_IQEE'+@cSep+
								CAST(ISNULL(@bOldTuteurDesireReleveElect,1) AS VARCHAR)+@cSep+
								CAST(ISNULL(C.bTuteur_Desire_Releve_Elect,1) AS VARCHAR)+@cSep+
								CASE 
									WHEN ISNULL(@bOldTuteurDesireReleveElect,1) = 0 THEN 'Non'
								ELSE 'Oui'
								END+@cSep+
								CASE 
									WHEN ISNULL(C.bTuteur_Desire_Releve_Elect,1) = 0 THEN 'Non'
								ELSE 'Oui'
								END+@cSep+
								CHAR(13)+CHAR(10)
						ELSE ''
						END +
						CASE 
							WHEN ISNULL(@iOldSous_Cat_ID_Resp_Prelevement,1) <> ISNULL(C.iSous_Cat_ID_Resp_Prelevement,0) THEN
								'iSous_Cat_ID_Resp_Prelevement'+@cSep+
								CAST(ISNULL(@iOldSous_Cat_ID_Resp_Prelevement,1) AS VARCHAR)+@cSep+
								CAST(ISNULL(C.iSous_Cat_ID_Resp_Prelevement,1) AS VARCHAR)+@cSep+
								CASE 
									WHEN ISNULL(@iOldSous_Cat_ID_Resp_Prelevement,1) = 0 THEN 'Non'
								ELSE 'Oui'
								END+@cSep+
								CASE 
									WHEN ISNULL(C.iSous_Cat_ID_Resp_Prelevement,1) = 0 THEN 'Non'
								ELSE 'Oui'
								END+@cSep+
								CHAR(13)+CHAR(10)
						ELSE ''
						END/*+
						CASE 
							WHEN ISNULL(@iOldJustificationConvIncompleteID,0) <> ISNULL(C.iID_Justification_Conv_Incomplete,0) THEN
								'iID_Justification_Conv_Incomplete'+@cSep+CAST(@iOldJustificationConvIncompleteID AS VARCHAR)+@cSep+CAST(C.iID_Justification_Conv_Incomplete AS VARCHAR)+@cSep+
								CASE @iOldJustificationConvIncompleteID
									WHEN 1 THEN 'Transfert In'
									ELSE ''
								END+@cSep+
								CASE C.iID_Justification_Conv_Incomplete
									WHEN 1 THEN 'Transfert In'
									ELSE ''
								END+@cSep+
								CHAR(13)+CHAR(10)
						ELSE ''
						END*/

--@iOldSous_Cat_ID_Resp_Prelevement	
					FROM dbo.Un_Convention C
					JOIN dbo.Mo_Human S ON S.HumanID = C.SubscriberID
					JOIN dbo.Mo_Human OS ON OS.HumanID = @iOldSubscriberID
					LEFT JOIN dbo.Mo_Human CS ON CS.HumanID = C.CoSubscriberID
					LEFT JOIN dbo.Mo_Human OCS ON OCS.HumanID = @iOldCoSubscriberID
					JOIN dbo.Mo_Human B ON B.HumanID = C.BeneficiaryID
					JOIN dbo.Mo_Human OB ON OB.HumanID = @iOldBeneficiaryID
					JOIN Un_Plan P ON P.PlanID = C.PlanID
					JOIN Un_Plan OP ON OP.PlanID = @iOldPlanID
					--LEFT JOIN Un_DiplomaText DT ON DT.DiplomaTextID = C.DiplomaTextID
					--LEFT JOIN Un_DiplomaText ODT ON ODT.DiplomaTextID = @iOldDiplomaTextID
					JOIN CRQ_LogAction LA ON LA.LogActionShortName = 'U'
					WHERE C.ConventionID = @ConventionID

			IF @@ERROR <> 0
				SET @ConventionID = -4

-----------------------------------------------------------------------------------------------------------
		-- VÉRIFIER S'IL Y A UN CHANGEMENT DE BÉNÉFICIAIRE	
		IF @iOldBeneficiaryID <> @BeneficiaryID 
			BEGIN
				-- 2009-11-24 : JFG : Dans le cas d'un changement de bénéficiaire, vérifier	si on doit faire un remboursement

				-- Recherche du lien entre les bénéficiaires et avec le souscripteur initial
				SELECT TOP 1
					 @bLien_Frere_Soeur_Avec_Ancien_Beneficiaire	=	cb.bLien_Frere_Soeur_Avec_Ancien_Beneficiaire
					,@bLien_Sang_Avec_Souscripteur_Initial			=	cb.bLien_Sang_Avec_Souscripteur_Initial
					,@vcCodeRaisonChangement						=	cb.vcCode_Raison
					,@dtDate_Changement_Beneficiaire				=	cb.dtDate_Changement_Beneficiaire
				FROM
					dbo.fntCONV_RechercherChangementsBeneficiaire(NULL, NULL, @ConventionID, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL) cb
				ORDER BY
					cb.dtDate_Changement_Beneficiaire DESC

				-- Recherche des montants SCEE et SCEE+
				SELECT 
					@mSCEE		= SUM(fCESG + fCESGINT),
					@mSCEESup	= SUM(fACESG + fACESGINT)
				FROM 
					dbo.fntPCEE_ObtenirSubventionBons (@ConventionID,NULL,GETDATE())

				SELECT	@mSCEE		= ISNULL(@mSCEE,0),
						@mSCEESup	= ISNULL(@mSCEESup,0)

				-- Situation 1 :	Si montant SCCE+ présent et que le nouveau bénéficiaire 
				--					n'est pas le frère ou la soeur de l'ancien bénéficiare,
				--					il faut créer un transaction de remboursement pour les montants
				--					de subventions SCEE et SCEE+.

				-- Situation 2 :	Si l'âge du bénéficiaire est de 21 ans ou plus alors, on
				--					on rembourse les montants SCEE et SCEE+.

				-- Situation 3 :	La convention possède un montant SCEE, mais pas de SCEE+
				--					et le lien entre les bénéficiaires n'est pas frère/soeur
				--					ou le lien entre le bénéficiaire et le souscripteur initial 
				--					n'est pas un lien de sang, alors on rembourse les montants SCEE.

				-- Situation 4 : Si les situations 1, 2 et 3 sont fausses et que la raison du changement
				--				 de bénéficiairen est DEC (vcCode_Raison).

				-- Récupérer l'âge du nouveau bénéficiaire
				SELECT @ageNouveauBeneficiaire =  DATEDIFF(yy,hb.BirthDate, GETDATE()) 
				FROM  dbo.Mo_Human hb 
				WHERE hb.HumanID = @BeneficiaryID

				-- Récupérer l'âge de l'ancien bénéficiaire
				SELECT @ageAncienBeneficiaire =  DATEDIFF(yy,hb.BirthDate, GETDATE()) 
				FROM  dbo.Mo_Human hb 
				WHERE hb.HumanID = @iOldBeneficiaryID

				DECLARE @bCondition1 INT
				DECLARE @bCondition2 INT
				SET @bCondition1 = 1 
				SET @bCondition2 = 1 

				-- Condition 1 - situation #3.
				IF (@mSCEE > 0 AND @mSCEESup = 0)
				BEGIN
					IF (@bLien_Frere_Soeur_Avec_Ancien_Beneficiaire = 1 AND @ageNouveauBeneficiaire < 21)
					BEGIN
						SET @bCondition1 = 1 -- Admissible
					END
					ELSE 
					BEGIN
						SET @bCondition1 = 0 -- Non admissible selon la condition 1.
					END
				END

				-- Condition 2 - Situation #3.				
				IF (@mSCEE > 0 AND @mSCEESup = 0)
				BEGIN
					IF (@bLien_Sang_Avec_Souscripteur_Initial = 1 AND @ageNouveauBeneficiaire < 21 AND @ageAncienBeneficiaire < 21)
					BEGIN
						SET @bCondition2 = 1 -- Admissible
					END
					ELSE
					BEGIN
						SET @bCondition2 = 0 -- Non admissible selon la condition 2.
					END
				END

				IF	((@bLien_Frere_Soeur_Avec_Ancien_Beneficiaire = 0) AND (@mSCEESup > 0))		-- Situation 1
					OR
					EXISTS(SELECT 1 FROM  dbo.Mo_Human hb WHERE hb.HumanID = @BeneficiaryID AND /*DATEDIFF(yy,hb.BirthDate, GETDATE())*/dbo.fn_Mo_Age(hb.BirthDate, GETDATE()) >= 21)	-- Situation 2 -- corrigé le 2011-06-03 DHuppé
			        /*OR ((@mSCEE > 0 AND @mSCEESup = 0) AND (@bLien_Frere_Soeur_Avec_Ancien_Beneficiaire = 0 OR @bLien_Sang_Avec_Souscripteur_Initial = 0))*/	-- Situation 3				
                    OR (@bCondition1 = 0 AND @bCondition2 = 0) -- Situation #3.
					BEGIN
						IF (@mSCEE > 0 OR @mSCEESup > 0)
						BEGIN
							-- APPEL DE LA CRÉATION DE LA TRANSACTION 'BÉNÉFICIAIRE NON-ADMISSIBLE' NÉCESSAIRE POUR LES REMBOURSEMENTS.
							EXECUTE @iResult = dbo.IU_UN_OperBNA @ConnectID, @ConventionID, @dtDate_Changement_Beneficiaire				
						END
					END	
					/*
					-- 2009-12-02 : JFG - Ajusté PPA (2010-01-28)
					-- Si le nouveau bénéficiaire n'a pas de demande de BEC, alors on créé une demande de BEC pour la convention suggérée.
					IF dbo.fnCONV_ObtenirConventionBEC(@BeneficiaryID, 0, NULL) < 0	-- pas de BEC actif sur une autre convention
						BEGIN
							-- Récupérer une convention BEC suggérée et cocher la case BEC
							UPDATE	dbo.Un_Convention
							SET		bCLBRequested = 1
							WHERE	
								ConventionID = dbo.fnCONV_ObtenirConventionBEC(@BeneficiaryID, 1, NULL)
						END
					*/
				ELSE -- Si on entre dans ce ELSE, cela indique que le changement de bénéficiaire est admissible.		
					BEGIN
						IF @vcCodeRaisonChangement = 'DEC' OR @vcCodeRaisonChangement = 'INV'			-- Situation 4
							BEGIN
								-- Vérification s'il existe des transactions 400-11 (sans erreur, non-annulée et non-renversée)
								-- dont la date de transaction est plus grande que la date de décès de l'ancien bénéficiaire
								-- et plus petite que la date de changement du bénéficiaire

								-- CURSEUR POUR BÂTIR LES BLOBS
								DECLARE curBlob	CURSOR LOCAL FAST_FORWARD
								FOR
									SELECT 
										ce4.OperID
										,ce4.CotisationID
										,o.OperDate
										,o.OperTypeID
									FROM
										dbo.Un_Oper o
										INNER JOIN dbo.Un_CESP400 ce4	
											ON o.OperID = ce4.OperID 
										INNER JOIN dbo.UN_Cotisation Co  -- 2010-05-18
											ON Co.CotisationID = Ce4.CotisationID
									WHERE
									--	ce4.dtTransaction BETWEEN	(SELECT h.DeathDate FROM dbo.Mo_Human h WHERE h.HumanId = @iOldBeneficiaryID) 
									--								AND 
									--								@dtDate_Changement_Beneficiaire
										Co.EffectDate BETWEEN	(SELECT h.DeathDate FROM dbo.Mo_Human h WHERE h.HumanId = @iOldBeneficiaryID) 
																	AND 
																	@dtDate_Changement_Beneficiaire
										AND
										ce4.iCESP800ID			IS NULL
										AND	
										ce4.iReversedCESP400ID	IS NULL
										AND
										ce4.CotisationID		IS NOT NULL -- 2010-02-22 : JFG : AJOUT, CAR AUTREMENT LE BLOB SERA CORROMPU PAR LA VALEUR NULL
										AND
										ce4.ConventionID		= @ConventionID	-- 2010-03-19 : JFG : Permet de traiter uniquement la convention passée en paramètre
										AND
										ce4.tiCESP400TypeID = 11 -- 2010-04-29 Doit être de type 11.

								-- INITIALISATION DES VARIABLES CONTENANT LES BLOBS							
								SET @vcLigneBlob			= ''
								SET @vcLigneBlobCotisation	= ''
								SET @iCompteLigne			= 0

								-- CONSTRUCTION DES BLOBS
								OPEN curBlob
								FETCH NEXT FROM curBlob INTO @iIDOperCur, @iIDCotisationCur, @dtDateOperCur, @cOperTypeID
								WHILE @@FETCH_STATUS = 0
									BEGIN
										--SET @vcLigneBlob			= @vcLigneBlob + 'Un_Oper' + ';' + CAST(ISNULL(@iCompteLigne,'') AS VARCHAR(8)) + ';' + CAST(ISNULL(@iIDOperCur,'') AS VARCHAR(8)) + ';' + CAST(ISNULL(@ConnectID,'') AS VARCHAR(10)) + ';BNA;' + ';' + CONVERT(VARCHAR(25), ISNULL(@dtDateOperCur,''), 121) + CHAR(13) + CHAR(10)
										SET @vcLigneBlob			= @vcLigneBlob + 'Un_Oper' + ';' + CAST(ISNULL(@iCompteLigne,'') AS VARCHAR(8)) + ';' + CAST(ISNULL(@iIDOperCur,'') AS VARCHAR(8)) + ';' + CAST(ISNULL(@ConnectID,'') AS VARCHAR(10)) + ';'+@cOperTypeID +';' + ';' + CONVERT(VARCHAR(25), ISNULL(@dtDateOperCur,''), 121) + CHAR(13) + CHAR(10)
										SET @vcLigneBlobCotisation	= @vcLigneBlobCotisation + CAST(ISNULL(@iIDCotisationCur,'') AS VARCHAR(10)) + ','
										FETCH NEXT FROM curBlob INTO @iIDOperCur, @iIDCotisationCur, @dtDateOperCur, @cOperTypeID
									END
								CLOSE curBlob
								DEALLOCATE curBlob

								IF (RTRIM(LTRIM(@vcLigneBlobCotisation)) <> '' AND RTRIM(LTRIM(@vcLigneBlobCotisation)) <> ',')
								BEGIN
									-- 2010-03-09 : JFG :	Mise en commentaire, car le seconde ligne ne doit pas avoir de char(13)/char(10)
									--						et la virgule en trop, doit y rester
									--SET @vcLigneBlobCotisation = LEFT(@vcLigneBlobCotisation, LEN(@vcLigneBlobCotisation) - 1) + CHAR(13) + CHAR(10)									

									-- INSERTION DES BLOBS
									EXECUTE @iIDBlob			= dbo.IU_CRI_BLOB 0, @vcLigneBlob
									EXECUTE @iIDCotisationBlob	= dbo.IU_CRI_BLOB 0, @vcLigneBlobCotisation

									-- RENVERSEMENT ET RENVOIS DES TRANSACTIONS
									EXEC @iResult = dbo.IU_UN_ReSendCotisationCESP400 @ConventionID, @iIDCotisationBlob, @iIDBlob, @ConnectID, @bSansVerificationPCEE400 -- 2010-04-29 : JFG : Ajout de @bSansVerificationPCEE400
								END

/*
								SET @vcLigneBlobCotisation = LEFT(@vcLigneBlobCotisation, LEN(@vcLigneBlobCotisation) - 1) + CHAR(13) + CHAR(10)

								-- INSERTION DES BLOBS
								EXECUTE @iIDBlob			= dbo.IU_CRI_BLOB 0, @vcLigneBlob
								EXECUTE @iIDCotisationBlob	= dbo.IU_CRI_BLOB 0, @vcLigneBlobCotisation

								-- RENVERSEMENT ET RENVOIS DES TRANSACTIONS
								EXEC @iResult = dbo.IU_UN_ReSendCotisationCESP400 @ConventionID, @iIDCotisationBlob, @iIDBlob 
*/
							END	
					END
				/*
				-- Sur un changement de bénéficiaire, quand le tuteur du nouveau bénéficiaire est différent du souscripteur 
				-- de la convention, que le code postal du tuteur est différent de celui du souscripteur ou que le lien  
				-- n'est pas père/mère et que le premier CPA ou PRD a déjà été déposé dans la convention, une lettre 
				-- d’émission au tuteur sera automatiquement commandée pour le tuteur du nouveau bénéficiaire.
				DECLARE cCnvTutorLetter CURSOR FOR
					SELECT DISTINCT 
						C.ConventionID
					FROM dbo.Un_Beneficiary B
					JOIN dbo.Un_Convention C ON C.BeneficiaryID = B.BeneficiaryID
					JOIN dbo.Mo_Human HT ON HT.HumanID = B.iTutorID
					JOIN dbo.Mo_Adr AdT ON AdT.AdrID = HT.AdrID
					JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
					JOIN dbo.Mo_Adr AdS ON AdS.AdrID = HS.AdrID
					WHERE C.ConventionID = @ConventionID -- Filtre sur la convention
						AND B.iTutorID <> C.SubscriberID -- Le tuteur n'est pas le souscripteur
						AND( C.tiRelationshipTypeID <> 1 -- Le lien n'est pas père/mère
							OR AdS.ZipCode <> AdT.ZipCode -- Le code postal du tuteur est différent de celui du souscripteur
							)
						AND ConventionID IN -- Un PRD ou un CPA a été versée
									(
									SELECT DISTINCT
										U.ConventionID
									FROM dbo.Un_Unit U
									JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
									JOIN Un_Oper O ON O.OperID = Ct.OperID
									WHERE U.ConventionID = @ConventionID -- Filtre sur la convention
										AND O.OperTypeID IN ('CPA', 'PRD')
									)

				OPEN cCnvTutorLetter

				FETCH NEXT FROM cCnvTutorLetter
				INTO
					@iConventionID

				WHILE @@FETCH_STATUS = 0 AND @ConventionID > 0
				BEGIN
					-- Lettre d'émission au tuteur légal
					EXECUTE @iResult = RP_UN_TutorLetter @ConnectID, @iConventionID, 0

					IF @iResult <= 0
						SET @ConventionID = -5

					FETCH NEXT FROM cCnvTutorLetter
					INTO
						@iConventionID
				END

				CLOSE cCnvTutorLetter
				DEALLOCATE cCnvTutorLetter
				*/
			END
		END
	END

	IF @ConventionID > 0
	AND EXISTS (	SELECT C.ConventionID
						FROM dbo.Un_Convention C
						WHERE C.ConventionID = @ConventionID
							-- Vérifie s'il y a des informations modifiés qui affecte les enregistrements 100, 200 ou 400
							OR C.SubscriberID <> @iOldSubscriberID
							OR C.CoSubscriberID <> @iOldCoSubscriberID
							OR C.BeneficiaryID <> @iOldBeneficiaryID
							OR C.PlanID <> @iOldPlanID
							OR C.tiRelationshipTypeID <> @tiOldRelationshipTypeID
					)
	BEGIN
		DECLARE @iExecResult INT

		-- Appelle de la procédure stockée qui gère les enregistrements 100, 200, et 400 de toutes les conventions du bénéficiaire.
		EXECUTE @iExecResult = TT_UN_CESPOfConventions @ConnectID, 0, 0, @ConventionID

		IF @iExecResult <= 0
			SET @ConventionID = -7
	END

	/* -- Remplacé par l'appel de la procédure psPCEE_ForcerDemandeCotisation
	-- Projet 'Formulaire RHDSC' -- MISE A JOUR CONVENTION
	IF @ConventionID > 0
	BEGIN
			-- Déclaration des tables temporaires pour les NAS.
			DECLARE @NASSouscripteur TABLE (vcNAS VARCHAR(75))
			DECLARE @NASBeneficiaire TABLE (vcNAS VARCHAR(75))

			-- Si la cases 'Formulaire reçu' et SCEE deviennent cochées en même temps.
			IF (@bOldFormulaireRecu = 0 AND @bFormulaireRecu = 1 AND @bOldCESGRequested = 0 AND @bCESGRequested = 1)
			BEGIN
				-- Récupération des NAS du bénéficiaire
				INSERT INTO @NASBeneficiaire (vcNAS)
				SELECT SocialNumber
				FROM UN_HumanSocialNumber 
				WHERE HumanID = @BeneficiaryID

				INSERT INTO @NASBeneficiaire (vcNAS)
				SELECT SocialNumber
				FROM dbo.Mo_Human H
				WHERE H.HumanID = @BeneficiaryID

				-- Récupération des NAS du souscripteur
				INSERT INTO @NASSouscripteur (vcNAS)
				SELECT SocialNumber
				FROM UN_HumanSocialNumber 
				WHERE HumanID = @SubscriberID

				-- Vérifier s'il existe des transactions 400-11 envoyées avant la date du jour dont la subvention n'avait pas été demandée (même bénéficiaire et même souscripteur) Et pas plus vieille que 36 mois.
				-- Si oui, alors on renverse ces transactions et on les envoi à nouveau avec demande de subvention = oui.

				DECLARE curBlob	CURSOR LOCAL FAST_FORWARD FOR
					SELECT C4.OperID, C4.CotisationID, C4.dtTransaction, O.OperTypeID 
						FROM UN_CESP400 C4 
						LEFT OUTER JOIN UN_CESP400 R4 ON C4.iCESP400ID = R4.iReversedCESP400id
						LEFT OUTER JOIN UN_Oper O ON C4.OperID = O.OperID
						WHERE C4.ConventionID = @ConventionID 
						AND C4.tiCESP400TypeID = 11 --Type cotisation.
						AND C4.bCESPDemand = 0 --Subvention non-demandée.
						AND C4.iCESP800ID IS NULL
						AND C4.vcBeneficiarySIN IN (SELECT vcNAS FROM @NASBeneficiaire) -- Gérer les changements de NAS.
						AND C4.vcSubscriberSINorEN IN (SELECT vcNAS FROM @NASSouscripteur) -- Gérer les changements de NAS.
						AND R4.iCESP400ID IS NULL -- Pas annulé
						AND C4.iReversedCESP400ID IS NULL -- Pas une annulation
						AND DATEDIFF(Month, C4.dtTransaction, GETDATE()) <= 36 -- À revoir avec la notion du 7ème jour du mois suivant.
						AND C4.dtTransaction < GETDATE()

					-- INITIALISATION DES VARIABLES CONTENANT LES BLOBS							
					SET @vcLigneBlob			= ''
					SET @vcLigneBlobCotisation	= ''
					SET @iCompteLigne			= 0

					-- CONSTRUCTION DES BLOBS
					OPEN curBlob
					FETCH NEXT FROM curBlob INTO @iIDOperCur, @iIDCotisationCur, @dtDateOperCur, @iID_OperTypeBlob
						WHILE @@FETCH_STATUS = 0
									BEGIN
										SET @vcLigneBlob			= @vcLigneBlob + 'Un_Oper' + ';' + CAST(@iCompteLigne AS VARCHAR(10)) + ';' + CAST(ISNULL(@iIDOperCur,'') AS VARCHAR(8)) + ';' + CAST(@ConnectID AS VARCHAR(10)) + ';' + CAST(ISNULL(@iID_OperTypeBlob,'') AS VARCHAR(10)) + ';' + ';' + CONVERT(VARCHAR(25), ISNULL(@dtDateOperCur,''), 121) + CHAR(13) + CHAR(10)
										SET @vcLigneBlobCotisation	= @vcLigneBlobCotisation + CAST(ISNULL(@iIDCotisationCur,'') AS VARCHAR(10)) + ','
										FETCH NEXT FROM curBlob INTO @iIDOperCur, @iIDCotisationCur, @dtDateOperCur, @iID_OperTypeBlob
									END
						CLOSE curBlob
						DEALLOCATE curBlob

						IF (RTRIM(LTRIM(@vcLigneBlobCotisation)) <> '' AND RTRIM(LTRIM(@vcLigneBlobCotisation)) <> ',')
						BEGIN
							-- 2010-03-09 : JFG :	Mise en commentaire, car le seconde ligne ne doit pas avoir de char(13)/char(10)
							--						et la virgule en trop, doit y rester
							--SET @vcLigneBlobCotisation = LEFT(@vcLigneBlobCotisation, LEN(@vcLigneBlobCotisation) - 1) + CHAR(13) + CHAR(10)

							-- INSERTION DES BLOBS
							EXECUTE @iIDBlob			= dbo.IU_CRI_BLOB 0, @vcLigneBlob
							EXECUTE @iIDCotisationBlob	= dbo.IU_CRI_BLOB 0, @vcLigneBlobCotisation

							-- RENVERSEMENT ET RENVOIS DES TRANSACTIONS
							EXEC @iResult = dbo.IU_UN_ReSendCotisationCESP400 @ConventionID, @iIDCotisationBlob, @iIDBlob, @ConnectID,  1 -- 2010-04-29 : JFG : Ajout de @bSansVerificationPCEE400
						END
			END
			-- Si la case 'BEC' était cochée et maintenant décochée.
			IF (@bOLDCLBRequested = 1 AND @bCLBRequested = 0)
			BEGIN
				DECLARE 
					@tConventionBECMaj	TABLE	
					(
						iID_Convention	INT PRIMARY KEY
					)
				DECLARE @iID_ConventionBECSuggeree INT

				-- Récupérer une convention BEC suggérée et cocher la case BEC
				UPDATE	dbo.Un_Convention
				SET		bCLBRequested = 1
				OUTPUT INSERTED.ConventionID INTO @tConventionBECMaj -- 2010-09-14 PPA
				WHERE	
					ConventionID = dbo.fnCONV_ObtenirConventionBEC(@BeneficiaryID, 1, @ConventionID)

				-- Crééer la demande de BEC
				IF EXISTS (SELECT 1 FROM @tConventionBECMaj)
				BEGIN
					SELECT @iID_ConventionBECSuggeree=iID_Convention FROM @tConventionBECMaj
					EXEC dbo.TT_UN_CLB @iID_ConventionBECSuggeree
				END
			END

----------- Si la case 'Formulaire reçu' est décochée.
--			IF (@bOldFormulaireRecu = 1 AND @bFormulaireRecu = 0 AND @bOldCESGRequested = 1 AND @bCESGRequested = 0)
			IF (@bOldFormulaireRecu = 1 AND @bFormulaireRecu = 0)
			BEGIN
				-- Récupération des NAS du bénéficiaire
				INSERT INTO @NASBeneficiaire (vcNAS)
				SELECT SocialNumber
				FROM UN_HumanSocialNumber 
				WHERE HumanID = @BeneficiaryID

				INSERT INTO @NASBeneficiaire (vcNAS)
				SELECT SocialNumber
				FROM dbo.Mo_Human H
				WHERE H.HumanID = @BeneficiaryID

				-- Récupération des NAS du souscripteur
				INSERT INTO @NASSouscripteur (vcNAS)
				SELECT SocialNumber
				FROM UN_HumanSocialNumber 
				WHERE HumanID = @SubscriberID

				-- Mise à jour des transactions 400-11 non-envoyés, on doit mettre bCESPDemand à NON.
				UPDATE UN_CESP400
				SET bCESPDemand = 0 
				WHERE Un_CESP400.iCESPSendFileID IS NULL
				AND Un_CESP400.ConventionID = @ConventionID
				AND Un_CESP400.tiCESP400TypeID = 11

				-- Vérifier s'il existe des transactions 400-11 envoyées avant la date du jour dont la subvention avait été demandée (même bénéficiaire et même souscripteur).
				-- Si oui, alors on renverse ces transactions et on les envoi à nouveau avec demande de subvention = NON.

				DECLARE curBlob	CURSOR LOCAL FAST_FORWARD FOR
					SELECT C4.OperID, C4.CotisationID, C4.dtTransaction, O.OperTypeID 
						FROM UN_CESP400 C4 
						LEFT OUTER JOIN UN_CESP400 R4 ON C4.iCESP400ID = R4.iReversedCESP400id
						LEFT OUTER JOIN UN_Oper O ON C4.OperID = O.OperID
						WHERE C4.ConventionID = @ConventionID 
						AND C4.tiCESP400TypeID = 11 --Type cotisation.
						AND C4.bCESPDemand = 1 --Subvention demandée.
						AND C4.iCESP800ID IS NULL
						AND C4.vcBeneficiarySIN IN (SELECT vcNAS FROM @NASBeneficiaire) -- Gérer les changements de NAS.
						AND C4.vcSubscriberSINorEN IN (SELECT vcNAS FROM @NASSouscripteur) -- Gérer les changements de NAS.
						AND R4.iCESP400ID IS NULL -- Pas annulé
						AND C4.iReversedCESP400ID IS NULL -- Pas une annulation
						AND C4.iCESPSendFileID IS NOT NULL -- Envoyée!

					-- INITIALISATION DES VARIABLES CONTENANT LES BLOBS							
					SET @vcLigneBlob			= ''
					SET @vcLigneBlobCotisation	= ''
					SET @iCompteLigne			= 0

					-- CONSTRUCTION DES BLOBS
					OPEN curBlob
					FETCH NEXT FROM curBlob INTO @iIDOperCur, @iIDCotisationCur, @dtDateOperCur, @iID_OperTypeBlob
						WHILE @@FETCH_STATUS = 0
									BEGIN
										SET @vcLigneBlob			= @vcLigneBlob + 'Un_Oper' + ';' + CAST(@iCompteLigne AS VARCHAR(10)) + ';' + CAST(ISNULL(@iIDOperCur,'') AS VARCHAR(8)) + ';' + CAST(@ConnectID AS VARCHAR(10)) + ';' + CAST(ISNULL(@iID_OperTypeBlob,'') AS VARCHAR(10)) + ';' + ';' + CONVERT(VARCHAR(25), ISNULL(@dtDateOperCur,''), 121) + CHAR(13) + CHAR(10)
										SET @vcLigneBlobCotisation	= @vcLigneBlobCotisation + CAST(ISNULL(@iIDCotisationCur,'') AS VARCHAR(10)) + ','
										FETCH NEXT FROM curBlob INTO @iIDOperCur, @iIDCotisationCur, @dtDateOperCur, @iID_OperTypeBlob
									END
						CLOSE curBlob
						DEALLOCATE curBlob

						IF (RTRIM(LTRIM(@vcLigneBlobCotisation)) <> '' AND RTRIM(LTRIM(@vcLigneBlobCotisation)) <> ',')
						BEGIN
							-- INSERTION DES BLOBS
							EXECUTE @iIDBlob			= dbo.IU_CRI_BLOB 0, @vcLigneBlob
							EXECUTE @iIDCotisationBlob	= dbo.IU_CRI_BLOB 0, @vcLigneBlobCotisation

							-- RENVERSEMENT ET RENVOIS DES TRANSACTIONS
							EXEC @iResult = dbo.IU_UN_ReSendCotisationCESP400 @ConventionID, @iIDCotisationBlob, @iIDBlob, @ConnectID,  1 
						END
					END
	END
	*/

	/*IF @ConventionID > 0 AND 
		(ISNULL(@bOldFormulaireRecu, 0) <> @bFormulaireRecu OR ISNULL(@bOldCESGRequested, 0) <> @bCESGRequested)
		EXEC @iResult = psPCEE_ForcerDemandeCotisation @ConventionID, @ConnectID
*/
	IF @ConventionID > 0
		------------------
		COMMIT TRANSACTION
		------------------
	ELSE
		--------------------
		ROLLBACK TRANSACTION
		--------------------
	RETURN @ConventionID
END