/****************************************************************************************************
Copyrights (c) 2013 Gestion Universitas inc.

Code du service		: psTEMP_CreerConvention_T_17ans
Nom du service		: Procedure pour créer une convention T pour un bénéficiaire de 17 ans
But 				: 
Facette				: TEMP

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	

		exec psTEMP_CreerConvention_T_17ans 
			@vcUserID = 'DHUPPE', 
			@ConventionNo = 'U-20030903010',
			@EnDateDu = '2018-02-08',
			@CreerConvention  = 0

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2013-08-28		Donald Huppé						Création du service		
		2014-10-23		Donald Huppé						glpi 12714 : ajout d'usager ayant accès
		2014-11-20		Donald Huppé						glpi 12913 : ajout de fmenard
		2015-01-09		Pierre-Luc Simard					Ne plus copier les valuers de la convention collective concernant les demandes de subventions
		2015-05-05		Donald Huppé						ajout de csamson
		2015-06-16		Donald Huppé						glpi 14886 : ajout d'usager ayant accès
		2015-07-29		Steve Picard						Utilisation du "Un_Convention.TexteDiplome" au lieu de la table UN_DiplomaText
		2016-04-29		Donald Huppé						Fait le 27 au lieu du 29 : Validation de l'existence d'une T : Si la T a été créée dans l'année en cours, on bloque.  Sinon on laisse en créer un nouveau.
		2016-04-28		Donald Huppé						Validation de l'existence d'une T : on valide à partir de year(@EnDateDu) au lieu de year(Getdate())
        2016-07-18      Pierre-Luc Simard                   Ajout de Cristel Héon
		2016-11-18		Donald Huppé						jira ti-5667 : ajout d'usager ayant accès
		2016-12-20		Donald Huppé						Ajout des paramètres @IDSouscripteurRemplacant et @IDBeneficiaireRemplacant
		2016-12-22		Donald Huppé						Changer malarrivee pour mlarrivee
		2017-04-12		Donald Huppé						Ajout de mgobeil (jira ti-7630)
		2017-08-03		Donald Huppé						Ajout de Eve Landry (ti-8664)
		2017-10-11		Donald Huppé						Ajout de jnorman (ti-9620)
		2017-11-21		Donald Huppé						Ajout de amelay
		2017-12-19		Donald Huppé						Ajout de mchaudey
        2017-12-29      Pierre-Luc Simard                   JIRA TI-10622: Retrait de la validation sur l'existence d'une T la même année
		2017-02-08		Donald Huppé						jira prod-7534 : envoyer @iID_RepComActif à IU_UN_Unit qui contient le repid du souscripteur
		2018-09-07		Maxime Martel						JIRA MP-1139: Désactiver la création automatique des frais de service
        2018-11-08      Pierre-Luc Simard                   Utilisation des regroupements de régimes, sauf pour Select 2000 Plan B
        2018-11-23		Donald Huppé						JIRA PROD-12935 : Ajout de kdubuc
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psTEMP_CreerConvention_T_17ans] 
(
	@vcUserID varchar(255),
	@ConventionNo VARCHAR(15),
	@EnDateDu datetime,
	@CreerConvention  bit = 0,
	@IDSouscripteurRemplacant INT = NULL,
	@IDBeneficiaireRemplacant INT = NULL
)
AS
BEGIN
	declare
		@iConventionID INT,
		@iConventionID_T INT,
		@UnitID int,
		@Souscripteur varchar(255),
		@SouscripteurRemplacant varchar(255),
		@BeneficiaireRemplacant varchar(255),
		@SubscriberID int,
		@BeneficiaryID int,
		@FaireConv int,
		@dtDateDuJour datetime,
		@ConnectID int,
		@cMessage varchar(500)
		,@iID_RepComActif INTEGER

	set @dtDateDuJour = GETDATE()
	set @dtDateDuJour = dbo.FN_CRQ_DateNoTime(@dtDateDuJour)

	if not exists (select 1 from sysobjects where Name = 'tblTEMP_ConventionT17ans')
		begin
		create table tblTEMP_ConventionT17ans (conventionno varchar(20), UserID varchar(255)) --drop table tblTEMP_TIOIQEE
		end

	-- On laisse un trace dans une table lors d'une demande demander de créer un RIO 
	IF 	@CreerConvention = 0
		begin
		delete from tblTEMP_ConventionT17ans 
		insert into tblTEMP_ConventionT17ans VALUES (@ConventionNo, @vcUserID)
		end

	set @cMessage = ''
	set @FaireConv = 1

	SELECT 
		@iConventionID = ConventionID,
		@Souscripteur = HS.FirstName + ' ' + HS.LastName,
		@SubscriberID = C.SubscriberID,
		@BeneficiaryID = C.BeneficiaryID

	FROM dbo.Un_Convention C
	JOIN dbo.Mo_Human HS ON C.SubscriberID = HS.HumanID
	WHERE ConventionNo = @ConventionNo and PlanID <> 4 -- select * from un_plan


	SELECT @SouscripteurRemplacant = HS.FirstName + ' ' + HS.LastName
	FROM Mo_Human hs
	WHERE HumanID = ISNULL(@IDSouscripteurRemplacant,0)

	SELECT @BeneficiaireRemplacant = HB.FirstName + ' ' + HB.LastName
	FROM Mo_Human hB
	WHERE HumanID = ISNULL(@IDBeneficiaireRemplacant,0)

    /*
	select @iConventionID_T = isnull(c.ConventionID,0)
	FROM dbo.Un_Convention  c
	join (
		select 
			Cs.conventionid ,
			ccs.startdate,
			cs.ConventionStateID
		from 
			un_conventionconventionstate cs
			join (
				select 
				conventionid,
				startdate = max(startDate)
				from un_conventionconventionstate
				--where LEFT(CONVERT(VARCHAR, startDate, 120), 10) <= '2011-10-31' -- Si je veux l'état à une date précise 
				group by conventionid
				) ccs on ccs.conventionid = cs.conventionid 
					and ccs.startdate = cs.startdate 
					and cs.ConventionStateID in ('REE','TRA') -- je veux les convention qui ont cet état
		) css on C.conventionid = css.conventionid
	where 
		PlanID = 4 
		AND ConventionNo like 'T-' + cast(year(@EnDateDu) as VARCHAR(4)) + '%'
		AND SubscriberID = @SubscriberID
		AND BeneficiaryID = @BeneficiaryID
	*/
	-- vérifier que la convention existe
	if ISNULL(@iConventionID,0) = 0
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Convention COLLECTIVE non trouvée.'
		set @FaireConv = 0
		--goto abort
		END


	if ISNULL(@IDSouscripteurRemplacant,0) <> 0 AND ISNULL(@IDBeneficiaireRemplacant,0) <> 0
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'On ne peut pas inscrire un souscripteur remplaçant Et un bénéficiaire remplaçant en même temps.'
		set @FaireConv = 0
		goto abort
		END		


	if ISNULL(@IDSouscripteurRemplacant,0) <> 0 
		AND NOT EXISTS (SELECT 1 FROM Un_Subscriber WHERE SubscriberID = @IDSouscripteurRemplacant)

		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Le souscripteur remplacant demandé n''existe pas.'
		set @FaireConv = 0
		goto abort
		END


	if ISNULL(@IDBeneficiaireRemplacant,0) <> 0 
		AND NOT EXISTS (SELECT 1 FROM Un_Beneficiary WHERE BeneficiaryID = @IDBeneficiaireRemplacant)

		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Le bénéficiaire remplacant demandé n''existe pas.'
		set @FaireConv = 0
		goto abort
		END

    /*
	if ISNULL(@iConventionID,0) <> 0 
		and @iConventionID_T <> 0

		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Une Convention T créée en ' + cast(year(@EnDateDu) as VARCHAR(4)) + ' existe déjà.'
		set @FaireConv = 0
		goto abort
		END
    */
	if @EnDateDu < @dtDateDuJour
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'La date demandée doit être >= à la date du jour.'
		set @FaireConv = 0
		--goto abort
		END

	-- vérification que l'usager à le droit
	if @vcUserID not like '%dhuppe%' and @vcUserID not like '%GBerthiaume%' and @vcUserID not like '%menicolas%'  

		and @vcUserID not like '%anadeau%'
		and @vcUserID not like '%csamson%'
		and @vcUserID not like '%apoirier%'
		and @vcUserID not like '%ggrondin%'
		and @vcUserID not like '%kdubuc%'
		and @vcUserID not like '%mcadorette%'
		and @vcUserID not like '%medurou%'
		and @vcUserID not like '%nlafond%'
		and @vcUserID not like '%spatoine%'
		and @vcUserID not like '%vlapointe%'
		and @vcUserID not like '%fmenard%'

		and @vcUserID not like '%cbourget%'
		and @vcUserID not like '%jcloutier%'
		and @vcUserID not like '%ktardif%'
		and @vcUserID not like '%mviens%'
		and @vcUserID not like '%sderoy%'
		and @vcUserID not like '%strichot%'
		and @vcUserID not like '%vlapointe%'
        and @vcUserID not like '%cheon%'

		and @vcUserID not like '%nbabin%'
		and @vcUserID not like '%gdumont%'
		and @vcUserID not like '%ktremblay%'
		and @vcUserID not like '%mderoo%'
		and @vcUserID not like '%mocliche%'
		and @vcUserID not like '%mperron%'
		and @vcUserID not like '%nfortin%'
		and @vcUserID not like '%guytremblay%'
		and @vcUserID not like '%atremblay%'
		and @vcUserID not like '%cpesant%'
		and @vcUserID not like '%bvigneault%'
		and @vcUserID not like '%mlarrivee%'
		and @vcUserID not like '%nababin%'
		and @vcUserID not like '%chroy%'
		and @vcUserID not like '%wphilippon%'
		and @vcUserID not like '%alafontaine%'

		and @vcUserID not like '%mgobeil%'
		and @vcUserID not like '%elandry%'
		and @vcUserID not like '%jnorman%'
		and @vcUserID not like '%amelay%'
		and @vcUserID not like '%mchaudey%'




		begin
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Usager non autorisé : ' + @vcUserID
		set @FaireConv = 0
		--goto abort
		end		


	if (ISNULL(@IDSouscripteurRemplacant,0) <> 0 OR ISNULL(@IDBeneficiaireRemplacant,0) <> 0 ) 
		and @vcUserID not like '%dhuppe%'
		and @vcUserID not like '%menicolas%'  

		and @vcUserID not like '%anadeau%'
		and @vcUserID not like '%csamson%'
		and @vcUserID not like '%apoirier%'
		and @vcUserID not like '%vlapointe%'
        and @vcUserID not like '%kdubuc%'


		and @vcUserID not like '%nbabin%'
		and @vcUserID not like '%mlarrivee%'
		and @vcUserID not like '%nababin%'
		and @vcUserID not like '%mcadorette%'

		begin
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Usager non autorisé pour inscrire un souscripteur ou bénéficiaire remplaçant : ' + @vcUserID
		set @FaireConv = 0
		--goto abort
		end	


	if @CreerConvention = 1 and not exists(SELECT 1 from tblTEMP_ConventionT17ans where conventionno = @ConventionNo)
		begin
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Attention. Demandez d''abord le rapport sans demander la création de la convention T !'
		set @FaireConv = 0
		--goto abort
		end

	-- Pour avoir un connectID récent du user qui fait la demande.
	SELECT @ConnectID = MAX(ct.ConnectID)
	from Mo_User u
	join Mo_Connect ct ON u.UserID = ct.UserID
	WHERE u.LoginNameID = REPLACE(@vcUserID,'UNIVERSITAS\','')	

	IF  (@ConnectID is NULL)
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Erreur : ConnectID non déterminé pour cet usager.'
		set @FaireConv = 0
		END

	IF  @FaireConv = 1 and @CreerConvention = 0
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Sélectionnez "Créer convention T = True" pour créer la convention.' 
				+ case WHEN @IDSouscripteurRemplacant is not null then char(10)  + '-----> POUR LE SOUSCRIPTEUR REMPLAÇANT MENTIONNÉ ' + @SouscripteurRemplacant + ' <-----' ELSE '' END
				+ case WHEN @IDBeneficiaireRemplacant is not null then char(10)  + '-----> POUR LE BÉNÉFICIAIRE REMPLAÇANT MENTIONNÉ ' + @BeneficiaireRemplacant + ' <-----' ELSE '' END
		END

	if @FaireConv = 1 and @CreerConvention = 1
		BEGIN	
			-- Faire la convention T

			SET @EnDateDu = dbo.FN_CRQ_DateNoTime(@EnDateDu)

			-----------------------------------------------------------------

			DECLARE	@iSousScripteur		INTEGER
					,@iCoSousScripteur	INTEGER
					,@iBeneficiaireID	INTEGER
					,@bCESGDemande		BIT
					,@bACESGDemande		BIT
					,@bCLBDemande		BIT
					,@tiCESPEtat		TINYINT
					,@tiRapportTypeID	TINYINT
					,@iSousCatID		INT
					,@bFormulaireRecu	INT

					--,@iDiplomaTextID					INT		-- 2015-07-29
					,@vcTexteDiplome					VARCHAR(max)
					,@bSendToCESP						BIT
					,@iDestinationRemboursementID		INT
					,@vcDestinationRemboursementAutre	VARCHAR(50)
					,@dtDateduProspectus				DATETIME
					,@bSouscripteurDesireIQEE			BIT
					,@tiLienCoSouscripteur				TINYINT
					,@bTuteurDesireReleveElect			BIT
					,@iPlanIDCollectif					INT
                    ,@vcRegroupementRegimeCollectif		VARCHAR(3)

					,@iConventionDestination			INT

					,@iCode_Retour						INTEGER
					,@dtDate_Fin_Convention_Collective	DATETIME
					,@iPlanID							INTEGER
					,@dtDateNaissance					DATETIME
					,@iAgeBeneficiaire					INT
					,@dtDateElevee						DATETIME
					,@iModalID							INTEGER
					,@iIDReSiegeSocial					INTEGER
					,@iIDSourceVente					INTEGER
					,@iRepResponsableID					INT
					,@iUniteDestination					INTEGER
					,@dtAujourdhui						DATETIME
					,@vcStatusGroupes					VARCHAR(10)

				IF object_id('tempdb..#DisableTrigger') is null
					CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))

				----------------------------
				BEGIN TRANSACTION
				----------------------------

			-------------------------------------------------------------------------------------------
			-- Créer la nouvelle convention individuelle
			---------------------------------------------------------------------------------------------
			SELECT	 @iSousScripteur	= ISNULL(@IDSouscripteurRemplacant,C.SubscriberID)
					,@iCoSousScripteur	= C.CoSubscriberID
					,@iBeneficiaireID	= ISNULL(@IDBeneficiaireRemplacant,C.BeneficiaryID)
					,@bCESGDemande		= C.bCESGRequested
					,@bACESGDemande		= C.bACESGRequested
					,@bCLBDemande		= C.bCLBRequested
					,@tiCESPEtat		= C.tiCESPState
					,@tiRapportTypeID	= C.tiRelationshipTypeID
					,@iSousCatID		= C.iSous_Cat_ID_Resp_Prelevement
					,@bFormulaireRecu	= C.bFormulaireRecu

			FROM	dbo.Un_Convention C
			WHERE C.ConventionID = @iConventionID

			INSERT INTO #DisableTrigger VALUES('TUn_Convention_State')		

			-- RÉCUPÉRER LES INFORMATIONS DE LA CONVENTION INITIALE
			SELECT	 @vcTexteDiplome					= c.TexteDiplome
					--,@iDiplomaTextID					= c.DiplomaTextID				-- 2015-07-29
					,@bSendToCESP						= c.bSendToCESP
					,@iDestinationRemboursementID		= c.iID_Destinataire_Remboursement
					,@vcDestinationRemboursementAutre	= c.vcDestinataire_Remboursement_Autre
					,@dtDateduProspectus				= c.dtDateProspectus
					,@bSouscripteurDesireIQEE			= c.bSouscripteur_Desire_IQEE
					,@tiLienCoSouscripteur				= c.tiID_Lien_CoSouscripteur
					,@bTuteurDesireReleveElect			= c.bTuteur_Desire_Releve_Elect
					,@iPlanIDCollectif					= c.PlanID
                    ,@vcRegroupementRegimeCollectif     = RR.vcCode_Regroupement

			FROM dbo.Un_Convention c
            JOIN Un_Plan P ON P.PlanID = c.PlanID 
            JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime

			WHERE c.ConventionID = @iConventionID

			EXEC  @iConventionDestination = dbo.IU_UN_Convention 
													 @ConnectID			-- @ConnectID 
													,0					-- @iConventionID
													,@iSousScripteur	-- @SubscriberID
													,@iCoSousScripteur	-- @CoSubscriberID
													,@iBeneficiaireID	-- @BeneficiaryID
													,4					-- @PlanID
													,'T'				-- @ConventionNo
													,@EnDateDu			-- @PmtDate
													,'CHQ'				-- @PmtTypeID
													,NULL				-- @GovernmentRegDate
													,-1  --@iDiplomaTextID	-- @DiplomaTextID -- 2015-07-29
													,@bSendToCESP		-- @bSendToCESP			-- Champ boolean indiquant si la convention doit être envoyée au PCEE (1) ou non (0).
													,0 --@bCESGDemande		-- @bCESGRequested		-- SCEE voulue (1) ou non (2)
													,0 --@bACESGDemande		-- @bACESGRequested		-- SCEE+ voulue (1) ou non (2)
													,0 --@bCLBDemande		-- @bCLBRequested		-- BEC voulu (1) ou non (2)
													,0 --@tiCESPEtat		-- @tiCESPState			-- État de la convention au niveau des pré-validations. (0 = Rien ne passe , 1 = Seul la SCEE passe, 2 = SCEE et BEC passe, 3 = SCEE et SCEE+ passe et 4 = SCEE, BEC et SCEE+ passe)
													,@tiRapportTypeID	-- @tiRelationshipTypeID -- ID du lien de parenté entre le souscripteur et le bénéficiaire.
													,@vcTexteDiplome		-- @DiplomaText			-- Texte du diplòme		-- 2015-07-29
													,@iDestinationRemboursementID		-- @iDestinationRemboursementID
													,@vcDestinationRemboursementAutre	-- @vcDestinationRemboursementAutre
													,@dtDateduProspectus				-- @dtDateduProspectus
													,@bSouscripteurDesireIQEE			-- @bSouscripteurDesireIQEE
													,@tiLienCoSouscripteur				-- @tiLienCoSouscripteur
													,@bTuteurDesireReleveElect			-- @bTuteurDesireReleveElect	
													,@iSousCatID						-- @iSous_Cat_ID_Resp_Prelevement	
													,0 --@bFormulaireRecu					-- @FormulaireRecu

			IF @@Error <> 0
				GOTO ROLLBACK_SECTION

			-------------------------------------------------------------------------------------------
			-- Mise à jour de la date de debut du régime de la convention individuelle
			-------------------------------------------------------------------------------------------
			UPDATE dbo.Un_Convention 
			SET dtRegStartDate = @EnDateDu
			WHERE ConventionID  = @iConventionDestination 

			IF @@Error <> 0
				GOTO ROLLBACK_SECTION

			-------------------------------------------------------------------------------------------
			-- Mise à jour de la date de fin du régime de la convention individuelle
			-------------------------------------------------------------------------------------------
			SET @dtDate_Fin_Convention_Collective = (SELECT [dbo].[fnCONV_ObtenirDateFinRegime](@iConventionID,'R',NULL))

			EXEC @iCode_Retour = IU_UN_ConvRegEndDateAdjust @iConventionDestination,@dtDate_Fin_Convention_Collective

			IF @@Error <> 0
				GOTO ROLLBACK_SECTION

			-------------------------------------------------------------------------------------------
			-- Creer Groupe d'unités à la nouvelle convention individuelle
			-------------------------------------------------------------------------------------------
			--Identifiant de Modalite de Paiement PlanID
			SELECT @iPlanID = C.PlanID
				,@iID_RepComActif = S.RepID
			FROM dbo.Un_Convention C
			JOIN Un_Subscriber S ON S.SubscriberID = C.SubscriberID
			WHERE C.ConventionID = @iConventionDestination

			--Date de naissance du bénéficiaire
			SELECT @dtDateNaissance = MH.BirthDate
			FROM dbo.Mo_Human MH
			WHERE HumanId = @iBeneficiaireID

			SET @dtAujourdhui = GETDATE()
			-- Appel de la fonction pour avoir l'age du beneficiaire
			EXEC @iAgeBeneficiaire = fn_Mo_Age @dtDateNaissance, @dtAujourdhui

			IF @@Error <> 0
				GOTO ROLLBACK_SECTION

			--Va chercher la date la plus élevée pour la modalité
			SELECT @dtDateElevee = MAX(Mod.ModalDate)
			FROM Un_Modal Mod

			WHERE	Mod.PlanID				= @iPlanID
			AND		Mod.PmtbyYearID			= 1
			AND		Mod.PmtQty				= 1 
			AND		Mod.BenefAgeOnBegining	= @iAgeBeneficiaire

			-- Identifiant unique de modalite  ModalID
			SELECT @iModalID = Mod.ModalID
			FROM Un_Modal Mod

			WHERE	Mod.PlanID = @iPlanID
			AND		Mod.ModalDate = @dtDateElevee
			AND		Mod.PmtbyYearID = 1
			AND		Mod.PmtQty = 1 
			AND		Mod.BenefAgeOnBegining = @iAgeBeneficiaire

			IF @iModalID < 0 
				BEGIN

				SET @iCode_Retour = -2
				GOTO ROLLBACK_SECTION

				END

			--Identifiant du representant du Siege Social
			SELECT @iIDReSiegeSocial = de.iID_Rep_Siege_Social
			FROM Un_Def de

			--Identifiant de la souce de vente avec une description commencant par SYS-RIO
			SELECT @iIDSourceVente =	CASE  
											WHEN @iPlanIDCollectif = 11 THEN
												(SELECT SaleSourceID
												FROM Un_SaleSource
												WHERE SaleSourceDesc LIKE ('SYS-MAX%') AND SaleSourceDesc LIKE ('%Plan B%'))

                                            WHEN @vcRegroupementRegimeCollectif = 'UNI' THEN
												(SELECT SaleSourceID
												FROM Un_SaleSource
												WHERE SaleSourceDesc LIKE ('SYS-MAX%') AND SaleSourceDesc LIKE ('%Universitas%'))

											WHEN @vcRegroupementRegimeCollectif = 'REF' THEN
												(SELECT SaleSourceID
												FROM Un_SaleSource
												WHERE SaleSourceDesc LIKE ('SYS-MAX%') AND SaleSourceDesc LIKE ('%Reeeflex%'))

										END

			-- Desactiver Trigger TUn_Unit_State
			INSERT INTO #DisableTrigger VALUES('TUn_Unit_State')

			-- RÉCUPÉRATION DU REPRÉSENTANT RESPONSABLE DE LA CONVENTION ORIGINAL
			SELECT @iRepResponsableID = u.RepResponsableID
			FROM dbo.Un_Unit u
			WHERE u.ConventionID = @iConventionID

			EXEC @iUniteDestination = IU_UN_Unit 
											@ConnectID				-- ID unique de connexion de l'usager
											,0							-- ID Unique du groupe d'unités (= 0 si on veut le créer)
											,@iConventionDestination	-- ID Unique de la convention à laquel appartient le groupe d'unités
											,@iModalID					-- ID Unique de la modalité de paiement
											,1							-- Quantité d'unités
											,@EnDateDu			-- Date de mise en vigueur
											,@EnDateDu			-- Date de la signature du contrat
											,NULL						-- Date du remboursement intégral (Null s'il n'a pas encore eu lieu)
											,NULL						-- Date de la résiliation (Null si elle n'a pas encore eu lieu)
											,NULL						-- ID Unique de l'assurance bénéficiaire (Null s'il n'y en a pas)
											,0							-- Champ boolean déterminant si le souscripteur à de l'assurance souscripteur ou non
											,@ConnectID				-- ID Unique de connection de l'usager qui à activé le groupe d'unités (Null si pas actif)
											,@ConnectID				-- ID Unique de connection de l'usager qui à validé le groupe d'unités (Null si pas valid‚)
											,@iIDReSiegeSocial			-- ID Unique du représentant qui a fait la vente
											,@iRepResponsableID			-- ID Unique du représentant responsable du représentant qui a fait la ventes s'il y a lieu.
											,0							-- Montant à ajouter au montant souscrit réel dans les relevés de dépôts
											,@iIDSourceVente			-- ID unique d'une source de vente de la table Un_SaleSource
											,NULL						-- Date de dernier dépôt pour relevé et contrat
											,@iSousCatID				-- ID de catégorie de groupe d'unités
											,@iID_RepComActif			-- ID DU REP DE LA COMMISSSION SUR L'ACTIF

			IF @@Error <> 0
					GOTO ROLLBACK_SECTION

			-------------------------------------------------------------------------------------------
			-- Mise à jour du groupe d'unite crée à l'etape précédente
			-------------------------------------------------------------------------------------------
			UPDATE dbo.Un_Unit 
			SET StopRepComConnectID = @ConnectID
			WHERE UnitID = @iUniteDestination

			IF @@Error <> 0
					GOTO ROLLBACK_SECTION

			-----------------------------------------------------------------------------------------------------------
			-- Réviser les statuts des groupes d'unités et les status
			-----------------------------------------------------------------------------------------------------------
			--Indique les status des groupes  d'unités
			SET @vcStatusGroupes  = CAST(@iUniteDestination AS VARCHAR)

			--Appel du service TT_UN_ConventionAndUnitStateForUnit
			EXEC TT_UN_ConventionAndUnitStateForUnit @vcStatusGroupes

			IF @@Error <> 0
					GOTO ROLLBACK_SECTION	

			-------------------------------------------------------------------------------------------
			-- Ajout de la convention à la table des catégories
			-------------------------------------------------------------------------------------------
			INSERT INTO tblCONV_ConventionConventionCategorie
				(
				 ConventionId
				,ConventionCategorieId
				)
			SELECT
				 @iConventionDestination
				,CC.ConventionCategoreId
			FROM tblCONV_ConventionCategorie CC
			WHERE CC.CategorieCode = 'R17'

			IF @@Error <> 0
				GOTO ROLLBACK_SECTION

			---------------------------------------------------------------------------------------------
			--	Application des frais de service
			---------------------------------------------------------------------------------------------
			--DECLARE	 @return_value		INT
			--		,@iID_Oper			INT
			--		,@vcCode_Msg		VARCHAR(10)
			--		,@vcMntFrais		VARCHAR(MAX)

			--EXECUTE @vcMntFrais = dbo.fnGENE_ObtenirParametre @vcCode_Type_Parametre = 'CONV_MNT_FRAIS_R17',
			--							@dtDate_Application = @EnDateDu
			--							,@vcDimension1 = NULL
			--							,@vcDimension2 = NULL
			--							,@vcDimension3 = NULL
			--							,@vcDimension4 = NULL
			--							,@vcDimension5 = NULL

			--EXEC	@return_value = psOPER_GenererOperationFrais
			--								 @iID_Connexion = @ConnectID
			--								,@iID_Convention = @iConventionDestination
			--								,@vcCode_Type_Frais = 'CUI'
			--								,@mMontant_Frais = @vcMntFrais
			--								,@iID_Utilisateur_Creation = NULL
			--								,@dtDate_Operation = @EnDateDu
			--								,@dtDate_Effective = @EnDateDu
			--								,@iID_Oper = @iID_Oper OUTPUT
			--								,@vcCode_Message = @vcCode_Msg OUTPUT

			--IF @@Error <> 0
			--	GOTO ROLLBACK_SECTION

			COMMIT_SECTION:
				COMMIT TRANSACTION
				GOTO END_TRANSACTION	

			ROLLBACK_SECTION:
				ROLLBACK TRANSACTION

			END_TRANSACTION:	
				IF object_id('tempdb..#DisableTrigger') is not null
					BEGIN

					-- Activer Trigger TUn_Convention_State
					Delete #DisableTrigger where vcTriggerName = 'TUn_Convention_State'

					-- Activer Trigger TUn_Unit_State
					Delete #DisableTrigger where vcTriggerName = 'TUn_Unit_State'

					END

					--SELECT @iConventionDestination		
					set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Convention T créé avec succès.'
					delete from tblTEMP_ConventionT17ans where conventionno = @ConventionNo

		END

	abort:

	select 
		LeMessage = MAX(LeMessage),
		ConventionCol= MAX(ConventionCol),
		ConventionT = MAX(ConventionT),
		Souscripteur = max(Souscripteur),
		SubscriberID = MAX(SubscriberID)
	from (
		-- convention collective
		SELECT 
			LeMessage = NULL,
			ConventionCol = C.ConventionNo,
			ConventionT = NULL,
			Souscripteur = HS.FirstName + ' ' + HS.LastName,
			SubscriberID = C.SubscriberID
		FROM dbo.Un_Convention C
		JOIN dbo.Mo_Human HS ON C.SubscriberID = HS.HumanID
		WHERE ConventionID = @iConventionID

		UNION

		-- convention T
		SELECT 
			LeMessage = NULL,
			ConventionCol = NULL,
			ConventionT = C.ConventionNo,
			Souscripteur = HS.FirstName + ' ' + HS.LastName,
			SubscriberID = C.SubscriberID
		FROM dbo.Un_Convention C
		JOIN dbo.Mo_Human HS ON C.SubscriberID = HS.HumanID
		WHERE ConventionID in ( @iConventionDestination)--,@iConventionID_T)

		Union

		-- Message
		SELECT 
			LeMessage = @cMessage,
			ConventionCol = NULL,
			ConventionT = NULL,
			Souscripteur = NULL,
			SubscriberID = NULL
		) V

END