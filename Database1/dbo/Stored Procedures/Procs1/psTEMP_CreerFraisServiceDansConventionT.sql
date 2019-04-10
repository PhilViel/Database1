/****************************************************************************************************
Copyrights (c) 2013 Gestion Universitas inc.

Code du service		: psTEMP_CreerFraisServiceDansConventionT
Nom du service		: Procedure pour créer les frais dans une convention T
But 				: 
Facette				: TEMP

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	

		exec psTEMP_CreerFraisServiceDansConventionT 
			@vcUserID = 'dhuppe', 
			@ConventionNo = 'T-20130828003',
			@EnDateDu = '2013-08-28',
			@CreerFrais  = 0

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2013-08-28		Donald Huppé						Création du service		
		2014-01-18		Donald Huppé						à la demande de G Berthiaume:  Enlever la validation : Il existe déjà un Frais dans la convention
															car il arrive qu'on fait plus d'un dépôt dans la convention alors il faut plus qu'un frais
		2014-10-23		Donald Huppé						glpi 12714 : ajout d'usager ayant accès
		2015-06-16		Donald Huppé						glpi 14886 : ajout d'usager ayant accès
		2015-07-02		Donald Huppé						glpi 15019 : ajout d'usager ayant accès
        2016-07-18      Pierre-Luc Simard                   Ajout de Cristel Héon
		2016-11-18		Donald Huppé						jira ti-5667 : ajout d'usager ayant accès
		2016-12-22		Donald Huppé						changer malarrivee pour mlarrivee
		2017-08-03		Donald Huppé						Ajout de Eve Landry (ti-8664)
		2017-10-11		Donald Huppé						Ajout de jnorman (ti-9620)
		2017-11-21		Donald Huppé						Ajout de amelay
        2018-09-20      Pierre-Luc Simard                   N'est plus utlisée, maintenant créé par Proacces
        2018-10-04      Pierre-Luc Simard                   Remise en place du rapport pour certains utilisateurs
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psTEMP_CreerFraisServiceDansConventionT] 
(
	@vcUserID varchar(255),
	@ConventionNo VARCHAR(15),
	@EnDateDu datetime,
	@CreerFrais  bit = 0
)
AS
BEGIN
    
    declare
		@iConventionID INT,
		@iConventionID_T INT,
		@UnitID int,
		@Souscripteur varchar(255),
		@SubscriberID int,
		@BeneficiaryID int,
		@FaireFrais int,
		@dtDateDuJour datetime,
		@ConnectID int,
		@cMessage varchar(500)
		
	set @dtDateDuJour = GETDATE()
	set @dtDateDuJour = dbo.FN_CRQ_DateNoTime(@dtDateDuJour)

	if not exists (select 1 from sysobjects where Name = 'tblTEMP_FraisService')
		begin
		create table tblTEMP_FraisService (conventionno varchar(20), UserID varchar(255)) 
		end

	-- On laisse un trace dans une table lors d'une demande demander de créer un RIO 
	IF 	@CreerFrais = 0
		begin
		delete from tblTEMP_FraisService 
		insert into tblTEMP_FraisService VALUES (@ConventionNo, @vcUserID)
		end

	set @cMessage = ''
	set @FaireFrais = 1

	SELECT 
		@iConventionID = ConventionID,
		@Souscripteur = HS.FirstName + ' ' + HS.LastName,
		@SubscriberID = C.SubscriberID,
		@BeneficiaryID = C.BeneficiaryID
		 
	FROM dbo.Un_Convention C
	JOIN dbo.Mo_Human HS ON C.SubscriberID = HS.HumanID
	WHERE 
		ConventionNo = @ConventionNo 
		and PlanID = 4 -- select * from un_plan
		and ConventionNO like 'T%'
	
	-- vérifier que la convention existe
	if ISNULL(@iConventionID,0) = 0
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Convention T non trouvée.'
		set @FaireFrais = 0
		--goto abort
		END

	if @EnDateDu < @dtDateDuJour
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'La date demandée doit être >= à la date du jour.'
		set @FaireFrais = 0
		--goto abort
		END

	-- vérification que l'usager à le droit
	if 
        @vcUserID not like '%dhuppe%' 
        AND @vcUserID not like '%GBerthiaume%' 
        AND @vcUserID not like '%kdubuc%'
		AND @vcUserID not like '%anadeau%'
		AND @vcUserID not like '%mchaudey%'
        AND @vcUserID not like '%vlapointe%'
        AND @vcUserID not like '%ggrondin%'
		AND @vcUserID not like '%ktardif%'
		AND @vcUserID not like '%mviens%'
		AND @vcUserID not like '%csamson%'
		AND @vcUserID not like '%apoirier%'		
        AND @vcUserID not like '%nbabin%'
        AND @vcUserID not like '%nababin%'
	    AND @vcUserID not like '%mlarrivee%'
		AND @vcUserID not like '%strichot%'
        AND @vcUserID not like '%cheon%'
        AND @vcUserID not like '%EBeaulieu%'
        AND @vcUserID not like '%MGobeil%'

		begin
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Usager non autorisé : ' + @vcUserID
		set @FaireFrais = 0
		--goto abort
		end		
	
	if @CreerFrais = 1 and not exists(SELECT 1 from tblTEMP_FraisService where conventionno = @ConventionNo)
		begin
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Attention. Demandez d''abord le rapport sans demander la création du Frais !'
		set @FaireFrais = 0
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
		set @FaireFrais = 0
		END
	/*
	IF EXISTS (SELECT 1
				FROM dbo.Un_Convention c
				JOIN dbo.Un_Unit u ON c.ConventionID = u.ConventionID
				JOIN Un_Cotisation ct ON u.UnitID = ct.UnitID
				JOIN Un_Oper o on ct.OperID = o.OperID
				WHERE c.ConventionNo = @ConventionNo
				and o.OperTypeID = 'FRS'
				--AND o.OperDate = @EnDateDu
				)
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Attention : Aye Guylaine viarge! Il existe déjà un Frais dans la convention.'
		set @FaireFrais = 0
		END	
*/
	IF  @FaireFrais = 1 and @CreerFrais = 0
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Sélectionnez "Créer Frais = True" pour créer le frais de service.'
		END

	if @FaireFrais = 1 and @CreerFrais = 1
		BEGIN	

		-----------------------------------------------------------------

		---------------------------------------------------------------------------------------------
		--	Application des frais de service
		---------------------------------------------------------------------------------------------
		DECLARE	 @return_value		INT
				,@iID_Oper			INT
				,@vcCode_Msg		VARCHAR(10)
				,@vcMntFrais		VARCHAR(MAX)

		EXECUTE @vcMntFrais = dbo.fnGENE_ObtenirParametre @vcCode_Type_Parametre = 'CONV_MNT_FRAIS_R17',
									@dtDate_Application = @EnDateDu
									,@vcDimension1 = NULL
									,@vcDimension2 = NULL
									,@vcDimension3 = NULL
									,@vcDimension4 = NULL
									,@vcDimension5 = NULL

		EXEC	@return_value = psOPER_GenererOperationFrais
										 @iID_Connexion = @ConnectID
										,@iID_Convention = @iConventionID
										,@vcCode_Type_Frais = 'CUI'
										,@mMontant_Frais = @vcMntFrais
										,@iID_Utilisateur_Creation = NULL
										,@dtDate_Operation = @EnDateDu
										,@dtDate_Effective = @EnDateDu
										,@iID_Oper = @iID_Oper OUTPUT
										,@vcCode_Message = @vcCode_Msg OUTPUT

		--SELECT @iConventionDestination		
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Bravo Guylaine ! Frais créé avec succès.'
		delete from tblTEMP_FraisService where conventionno = @ConventionNo

		END
	
	abort:
	
	select 
		LeMessage = MAX(LeMessage),
		Convention= MAX(Convention),
		Souscripteur = max(Souscripteur),
		SubscriberID = MAX(SubscriberID)
	from (
		-- convention
		SELECT 
			LeMessage = NULL,
			Convention = C.ConventionNo,
			Souscripteur = HS.FirstName + ' ' + HS.LastName,
			SubscriberID = C.SubscriberID
		FROM dbo.Un_Convention C
		JOIN dbo.Mo_Human HS ON C.SubscriberID = HS.HumanID
		WHERE ConventionID = @iConventionID

		Union
		
		-- Message
		SELECT 
			LeMessage = @cMessage,
			Convention = NULL,
			Souscripteur = NULL,
			SubscriberID = NULL
		) V
END
