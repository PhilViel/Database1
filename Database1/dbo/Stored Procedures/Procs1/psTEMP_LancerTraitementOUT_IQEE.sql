/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psTEMP_LancerTraitementOUT_IQEE
Nom du service		: Procedure pour compléter les OUT d'IQEE
But 				: compléter les OUT d'IQEE
Facette				: TEMP

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2013-02-11		Donald Huppé						Création du service		
		2013-05-23		Donald Huppé						glpi 9689 - ajustement pour ne pas proposer un out qui n'est pas la dernière opération dans la convention
		2015-09-25		Donald Huppé						glpi 15671 : user permis : Mcadorette et NLafond
		2015-11-26		Pierre-Luc Simard				    Ajout de medurou
        2016-11-02		Pierre-Luc Simard				    Ajout de cheon et cbourget
		2016-11-25		Donald Huppé						jira ti-5746 : Ajout de strichot
		2017-07-27		Steve Picard						Jira TI-8542 : Ajout de «anadeau» & «mviens»
		2017-08-15		Donald Huppé						Vérifier la présence d'un OUT existant dans UN_CESP, au lieu de seulement dans Un_ConventionOper
															Car si le OUT ne contient pas de rendement (dans Un_ConventionOper), alors on ne trouve pas l'opératon OUT,
															car elle est seulement dans UN_CESP
		2018-05-02		Donald Huppé						jira ti-12442 : Bloquer la création de OUT inexistant et forcer la @dtDateTransfert = Date du jour

exec psTEMP_LancerTraitementOUT_IQEE 
	@UserID = 'DHUPPE', 
	@ConventionNo = 'U-20091203068',
	@dtDateTransfert = '2013-01-01',
	@CreerOUT  = 1

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psTEMP_LancerTraitementOUT_IQEE] 
(
	@UserID varchar(255),
	@ConventionNo VARCHAR(15),
	@dtDateTransfert datetime,
	@CreerOUT  bit = 0
)
AS
BEGIN
	declare
		@ConventionID INT,
		@FaireTransfert int,
		@cMessage varchar(500),

		@OUTNonTrouve1 bit/* = 0*/,
		@OUTNonTrouve2 bit/* = 0*/,
		
		@mSolde_Credit_Base MONEY,
		@mSolde_Majoration MONEY,
		@mSolde_Interets_RQ MONEY,
		@mSolde_Interets_IQI MONEY,
		@mSolde_Interets_ICQ MONEY,
		@mSolde_Interets_IMQ MONEY,
		@mSolde_Interets_IIQ MONEY,
		@mSolde_Interets_III MONEY,
		@iCode_Retour int,
		@OtherOUTdate VARCHAR(10)

	DECLARE @tblResultatDebug	TABLE(
								vNoConvention			VARCHAR(15)			
								,vIdConvention			INT
								,vIdTransac				INT
								,vOUTExistant			varchar(3)
								,vOUTCreer				varchar(3)
								,vcGestionPerte			VARCHAR(20)
								,vOperId				INT
								,mSolde_Credit_Base		MONEY
								,mSolde_Majoration		MONEY
								,mSolde_Interets_RQ		MONEY
								,mSolde_Interets_IQI		MONEY
								,mSolde_Interets_ICQ		MONEY
								,mSolde_Interets_IMQ		MONEY
								,mSolde_Interets_IIQ		MONEY
								,mSolde_Interets_III		MONEY
								)

		set @OUTNonTrouve1 = 0
		set @OUTNonTrouve2 = 0

	if not exists (select 1 from sysobjects where Name = 'tblTEMP_OUTIQEE')
		begin
		create table tblTEMP_OUTIQEE (conventionno varchar(20), DateInsert datetime) --drop table tblTEMP_TIOIQEE
		end

	-- On laisse un trace dans une table lors d'une demande sans montant de TIO. Afin de vérifier ultérieurement, lors d'une demande avec montant de TIO, 
	-- qu'une demande de rapport a déjà été faite sans montant de TIO
	IF 	@CreerOUT = 0
		begin
		delete from tblTEMP_OUTIQEE 
		insert into tblTEMP_OUTIQEE VALUES (@ConventionNo, getdate())
		end

	set @cMessage = ''
	set @FaireTransfert = 1
	
	--select * from tblTEMP_OUTIQEE
	
	SELECT @ConventionID = ConventionID FROM dbo.Un_Convention WHERE ConventionNo = @ConventionNo
	
	-- vérifier que la convention existe
	if ISNULL(@ConventionID,0) = 0
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Convention non trouvée.'
		set @FaireTransfert = 0
		goto abort
		END

	-- 2018-05-02 : jira ti-12442
	if CAST(@dtDateTransfert AS DATE) <> CAST(GETDATE() AS DATE)
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'La date du OUT doit être la date du jour. --> Voyez votre superviseur.'
		set @FaireTransfert = 0
		goto abort
		END


	-- 2018-05-02 : jira ti-12442
	if ISNULL(@CreerOUT,0) <> 0
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Création de OUT inexistant INTERDIT. --> Voyez votre superviseur.'
		set @FaireTransfert = 0
		goto abort
		END


	-- faire même vérification que dans la sp psTEMP_CompleterTransfertOUTExterieur
	if not exists (

			SELECT TOP 1 V.OperId
			FROM (
				-- OperID de rendement
				SELECT 
					O.OperId
				FROM
					Un_Convention C	 	  
					JOIN Un_ConventionOper CO ON CO.ConventionID = C.ConventionID 		
					JOIN Un_Oper O ON O.OperID = CO.OperID	 
					LEFT JOIN Un_OperCancelation OC1 ON OC1.OperSourceID = O.OperID
					LEFT JOIN Un_OperCancelation OC2 ON OC2.OperID = O.OperID
				WHERE O.OperTypeID = 'OUT'
					AND O.OperDate = @dtDateTransfert
					AND C.ConventionNO = @ConventionNo
					AND OC1.OperSourceID IS NULL
					AND OC2.OperSourceID IS NULL

				UNION ALL

				-- OperID de SCEE
				SELECT
					CE.OperID
				FROM	
					Un_CESP CE
					JOIN Un_Convention C ON C.ConventionID = CE.ConventionID
					JOIN UN_OPER O ON O.OperID = CE.OperID
					LEFT JOIN Un_OperCancelation OC1 ON OC1.OperSourceID = O.OperID
					LEFT JOIN Un_OperCancelation OC2 ON OC2.OperID = O.OperID
				WHERE O.OperTypeID = 'OUT'
					AND O.OperDate = @dtDateTransfert
					AND C.ConventionNO = @ConventionNo
					AND OC1.OperSourceID IS NULL
					AND OC2.OperSourceID IS NULL
					)V

			--SELECT 
			--	TOP 1
			--	O.OperId
			--FROM
			--	Un_Convention C	 	  
			--	  INNER JOIN Un_ConventionOper CO ON CO.ConventionID = C.ConventionID 		
			--	  INNER JOIN Un_Oper O ON O.OperID = CO.OperID	 
			--	  LEFT JOIN Un_OperCancelation OC1 ON OC1.OperSourceID = O.OperID
			--	  LEFT JOIN Un_OperCancelation OC2 ON OC2.OperID = O.OperID
			--WHERE O.OperTypeID = 'OUT'
			--	AND O.OperDate = @dtDateTransfert
			--	AND C.ConventionNO = @ConventionNo
			--	AND OC1.OperSourceID IS NULL
			--	AND OC2.OperSourceID IS NULL
			--ORDER BY
			--	O.OperDate DESC		
			)

		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'PAS de OUT trouvé le : ' + LEFT(CONVERT(VARCHAR, @dtDateTransfert, 120), 10)  + '.'
		set @OUTNonTrouve1 = 1
		set @FaireTransfert = 0
		
		END

	if @OUTNonTrouve1 = 1 and exists 
		(
		SELECT TOP 1 O.OPERID
		FROM
			Un_Convention C	 	  
			  INNER JOIN Un_ConventionOper CO ON CO.ConventionID = C.ConventionID 		
			  INNER JOIN Un_Oper O ON O.OperID = CO.OperID	
			  join Un_OUT ot on O.OperID = ot.OperID 
			  LEFT JOIN Un_OperCancelation OC1 ON OC1.OperSourceID = O.OperID
			  LEFT JOIN Un_OperCancelation OC2 ON OC2.OperID = O.OperID
		WHERE O.OperTypeID = 'OUT'
			AND C.ConventionNO = @ConventionNo
			AND OC1.OperSourceID IS NULL
			AND OC2.OperSourceID IS NULL
			AND	ot.ExternalPlanID NOT IN (86,87,88) -- Id correspondant au promoteur Universitas
			and O.OperID = (  -- on s'Assure que le out trouvé est la dernière opération dans la convention		
						SELECT MAX(co.OperID)
						FROM dbo.Un_Convention c
						join Un_ConventionOper co on c.ConventionID = co.ConventionID
						where c.ConventionNo = @ConventionNo
					)
			)	
		BEGIN
			SELECT @OtherOUTdate = LEFT(CONVERT(VARCHAR, max(O.operdate), 120), 10)-- On informe l'usager
			FROM
				Un_Convention C	 	  
				  INNER JOIN Un_ConventionOper CO ON CO.ConventionID = C.ConventionID 		
				  INNER JOIN Un_Oper O ON O.OperID = CO.OperID	
				  join Un_OUT ot on O.OperID = ot.OperID 
				  LEFT JOIN Un_OperCancelation OC1 ON OC1.OperSourceID = O.OperID
				  LEFT JOIN Un_OperCancelation OC2 ON OC2.OperID = O.OperID
			WHERE O.OperTypeID = 'OUT'
				AND C.ConventionNO = @ConventionNo
				AND OC1.OperSourceID IS NULL
				AND OC2.OperSourceID IS NULL
				AND	ot.ExternalPlanID NOT IN (86,87,88)
				and O.OperID = (  -- on s'Assure que le out trouvé est la dernière opération dans la convention		
							SELECT MAX(co.OperID)
							FROM dbo.Un_Convention c
							join Un_ConventionOper co on c.ConventionID = co.ConventionID
							where c.ConventionNo = @ConventionNo
						)
			SET @OUTNonTrouve1 = 0 -- on présume donc qu'on a trouvé un OUT.
			SET @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'MAIS OUT trouvé le : ' + @OtherOUTdate  + '.' + char(10) + 'Sélectionnez ' + @OtherOUTdate + ' comme date de transfert et lancer le traitement.' 
		END

	-- faire même vérification que dans la sp psTEMP_CompleterTransfertOUTExterieur
	if not exists (
			SELECT TOP 1					
				O.OperId
			FROM         
				Un_Cotisation C
				INNER JOIN Un_Oper O ON C.OperID = O.OperID 
				INNER JOIN dbo.Un_Unit U ON C.UnitID = U.UnitID 
				INNER JOIN dbo.Un_Convention CO ON U.ConventionID = CO.ConventionID
				INNER JOIN Un_OUT ON O.OperId = Un_OUT.OperId
				INNER JOIN Un_ExternalPlan ON Un_ExternalPlan.ExternalPlanID = Un_OUT.ExternalPlanID
				INNER JOIN Un_ExternalPromo ON Un_ExternalPromo.ExternalPromoID = Un_ExternalPlan.ExternalPromoID
				INNER JOIN Mo_Company ON Mo_Company.CompanyID = Un_ExternalPromo.ExternalPromoID
			WHERE
				CO.ConventionNo = @ConventionNo 
				AND
				O.OperTypeID = 'OUT'
				AND
				Un_OUT.ExternalPlanID NOT IN (86,87,88) -- Id correspondant au promoteur Universitas
			ORDER BY
				O.OperDate DESC	
		)
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Aucun OUT **EXTERNE** trouvé.  Traitement impossible.'
		set @OUTNonTrouve2 = 1
		set @FaireTransfert = 0
		END
		
		-- si on ne trouve pas de OUT à la date demandé mais qu'il y a un autre OUT externe, on demande s'il veut générer un nouveau OUT.
		-- dans la sp psTEMP_CompleterTransfertOUTExterieur utilisé avec la méthode du fichier Excel, on ne posait pas la question et on gÉnérait un nouveau OUT
		-- Mais ici, je préfère avertir l'usager.
		if @CreerOUT = 0 and @OUTNonTrouve1 = 1 AND @OUTNonTrouve2 = 0
			BEGIN
			set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Cochez "forcer le OUT" pour le générer automatiquement.'
			set @OUTNonTrouve2 = 1
			set @FaireTransfert = 0
			END		
		
		-- Vérification des soldes négatifs
		if ISNULL(@ConventionID,0) <> 0
		
		BEGIN
		
			SELECT @mSolde_Credit_Base = ISNULL(SUM(CO.ConventionOperAmount),0)
			FROM Un_ConventionOper CO
			WHERE CO.ConventionID = @ConventionID
			  AND CO.ConventionOperTypeID = 'CBQ'

			SELECT @mSolde_Majoration = ISNULL(SUM(CO.ConventionOperAmount),0)
			FROM Un_ConventionOper CO
			WHERE CO.ConventionID = @ConventionID
			  AND CO.ConventionOperTypeID = 'MMQ'

			SELECT @mSolde_Interets_RQ = ISNULL(SUM(CO.ConventionOperAmount),0)
			FROM Un_ConventionOper CO
			WHERE CO.ConventionID = @ConventionID
			  AND CO.ConventionOperTypeID = 'MIM'

			SELECT @mSolde_Interets_IQI = ISNULL(SUM(CO.ConventionOperAmount),0)
			FROM Un_ConventionOper CO
			WHERE CO.ConventionID = @ConventionID
			  AND CO.ConventionOperTypeID = 'IQI'

			SELECT @mSolde_Interets_ICQ = ISNULL(SUM(CO.ConventionOperAmount),0)
			FROM Un_ConventionOper CO
			WHERE CO.ConventionID = @ConventionID
			  AND CO.ConventionOperTypeID = 'ICQ'

			SELECT @mSolde_Interets_IMQ = ISNULL(SUM(CO.ConventionOperAmount),0)
			FROM Un_ConventionOper CO
			WHERE CO.ConventionID = @ConventionID
			  AND CO.ConventionOperTypeID = 'IMQ'

			SELECT @mSolde_Interets_IIQ = ISNULL(SUM(CO.ConventionOperAmount),0)
			FROM Un_ConventionOper CO
			WHERE CO.ConventionID = @ConventionID
			  AND CO.ConventionOperTypeID = 'IIQ'

			SELECT @mSolde_Interets_III = ISNULL(SUM(CO.ConventionOperAmount),0)
			FROM Un_ConventionOper CO
			WHERE CO.ConventionID = @ConventionID
			  AND CO.ConventionOperTypeID = 'III'

			IF @mSolde_Credit_Base < 0 OR
				@mSolde_Majoration < 0 OR
				@mSolde_Interets_RQ < 0 OR
				@mSolde_Interets_IQI < 0 OR
				@mSolde_Interets_ICQ < 0 OR
				@mSolde_Interets_IMQ < 0 OR
				@mSolde_Interets_IIQ < 0 OR
				@mSolde_Interets_III < 0
		
				BEGIN
				set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Rendement négatifs. ARI à Faire dabord.'
				set @FaireTransfert = 0
				END
		
		END	
		
	-- vérification que l'usager à le droit
	if @UserID not like '%dhuppe%' 
			and @UserID not like '%fmenard%' 
			and @UserID not like '%MGobeil%' 
			and @UserID not like '%menicolas%' 
			and @UserID not like '%mcadorette%' 
			and @UserID not like '%nlafond%' 
			and @UserID not like '%medurou%' 
			and @UserID not like '%cheon%' 
			and @UserID not like '%cbourget%'
			and @UserID not like '%strichot%'
			and @UserID not like '%anadeau%'
			and @UserID not like '%mviens%'
		begin
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Usager non autorisé : ' + @UserID
		set @FaireTransfert = 0
		goto abort
		end

	-- Dans le cas où l'usager demande de créer un nouveau OUT, je vérifie qu'il a d'abord demandé sans le demander, question de s'assurer qu'il a vu les messages
	IF  @CreerOUT = 1
		AND not exists (SELECT 1 from tblTEMP_OUTIQEE where conventionno = @ConventionNo) 
		AND (@OUTNonTrouve1 = 0 or @OUTNonTrouve2 = 0)
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'ATTENTION. Demandez d''abord le traitement sans Cocher "Creer OUT inexistant".'
		set @FaireTransfert = 0
		END
		
	IF  @CreerOUT = 1
		AND exists (SELECT 1 from tblTEMP_OUTIQEE where conventionno = @ConventionNo) 
		AND (@OUTNonTrouve1 = 0 or @OUTNonTrouve2 = 0)
		BEGIN
		set @FaireTransfert = 1
		END

	if @FaireTransfert = 1
	
		begin

		-- inserer la demande dans tblTEMP_TransacManuelleIQEE
		INSERT INTO tblTEMP_TransacManuelleIQEE(vConventionNo ,dtDateTransfert,dtDateCheque,mIQEE ,mRendIQEE,mIQEE_Plus,mRendIQEE_Plus,cTraiter,vcTypeTransfert) 
		VALUES(@ConventionNo,@dtDateTransfert,NULL,NULL,NULL,NULL,NULL,'N','OUT')
		
		-- Faire la job.  comme les validation sont déjà faites, ça devrait passer comme du beures dans la poêle (ou comme papa dans maman)
		insert into @tblResultatDebug
		EXEC @iCode_Retour = psTEMP_CompleterTransfertOUTExterieur @ConventionNo, 1
	
		delete from tblTEMP_OUTIQEE where conventionno = @ConventionNo
	
		-- vérifier que la job a pas planté
		if @iCode_Retour <> 0
			begin
			set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Erreur de traitement. Communiquer avec les TI. '
			end	
	
		end	
	
	-- si la job a rien fait, je supprime l'entrée dans tblTEMP_TransacManuelleIQEE.  elle sera créé à nouveau s'il y a une nouvelle demande
	if exists (select 1 from @tblResultatDebug where vNoConvention = @ConventionNo and vOUTExistant = 'NON' and vOUTCreer = 'NON')
		begin
		delete from tblTEMP_TransacManuelleIQEE where vConventionNo = @ConventionNo and dtDateTransfert = @dtDateTransfert and cTraiter = 'N' and vcTypeTransfert = 'OUT'
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Traitement NON effectué. Aucun OUT trouvé.'
		end

	-- si un OUT a été créé, je suprpimer toute demande nono traité de cette convention au cas où il y en a, mais ça devrait pas.
	if exists (select 1 from @tblResultatDebug where vNoConvention = @ConventionNo and vOUTExistant = 'NON' and vOUTCreer = 'OUI')
		begin
		delete from tblTEMP_TransacManuelleIQEE where vConventionNo = @ConventionNo and dtDateTransfert = @dtDateTransfert and cTraiter = 'N' and vcTypeTransfert = 'OUT'
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Nouveau OUT créé.'
		end

	-- si un OUT était existant en daye demandée, je suprpimer toute demande non traité de cette convention au cas où il y en a, mais ça devrait pas.
	if exists (select 1 from @tblResultatDebug where vNoConvention = @ConventionNo and vOUTExistant = 'OUI' and vOUTCreer = 'NON')
		begin
		delete from tblTEMP_TransacManuelleIQEE where vConventionNo = @ConventionNo and dtDateTransfert = @dtDateTransfert and cTraiter = 'N' and vcTypeTransfert = 'OUT'
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'OUT existant complété.'
		end	
	
	abort:
	
	select
		LeMessage = @cMessage
	into #tMessage
	
	select
		m.LeMessage,
		vNoConvention = isnull(vNoConvention,'')
		,vIdConvention = isnull(vIdConvention ,0)
		,vIdTransac = isnull(vIdTransac ,0)
		,vOUTExistant = isnull(vOUTExistant,'')
		,vOUTCreer = isnull(vOUTCreer ,'')
		,vcGestionPerte = isnull(vcGestionPerte ,'')
		,vOperId = isnull(vOperId ,0)
		,mSolde_Credit_Base = isnull(mSolde_Credit_Base ,0)
		,mSolde_Majoration = isnull(mSolde_Majoration ,0)
		,mSolde_Interets_RQ = isnull(mSolde_Interets_RQ ,0)
		,mSolde_Interets_IQI = isnull(mSolde_Interets_IQI ,0)
		,mSolde_Interets_ICQ = isnull(mSolde_Interets_ICQ ,0)
		,mSolde_Interets_IMQ = isnull(mSolde_Interets_IMQ ,0)
		,mSolde_Interets_IIQ = isnull(mSolde_Interets_IIQ ,0)
		,mSolde_Interets_III = isnull(mSolde_Interets_III ,0)
	from 
		#tMessage m
	left join @tblResultatDebug r on 1=1
	
END
