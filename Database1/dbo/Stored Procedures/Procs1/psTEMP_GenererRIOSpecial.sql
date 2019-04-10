/****************************************************************************************************
    *************************************************************
    *     _____                                _           _    *
    *    |  __ \                              | |         | |   *
    *    | |  | | ___ _ __  _ __ ___  ___ __ _| |_ ___  __| |   *
    *    | |  | |/ _ \ '_ \| '__/ _ \/ __/ _` | __/ _ \/ _` |   *
    *    | |__| |  __/ |_) | | |  __/ (_| (_| | ||  __/ (_| |   *
    *    |_____/ \___| .__/|_|  \___|\___\__,_|\__\___|\__,_|   *
    *                | |                                        *
    *                |_|                                        *
    ******************** D E P R E C A T E D ********************

*/
/****************************************************************************************************
Copyrights (c) 2013 Gestion Universitas inc.

Code du service		: psTEMP_GenererRIOSpecial
Nom du service		: Procedure pour créer un RIO spécial
But 				: Créer un RIO spécial dans une convention qui n'a plus de solde de cotisation + frais
Facette				: TEMP

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	

		exec psTEMP_GenererRIOSpecial 
			@vcUserID = 'DHUPPE', 
			@ConventionNo = '1458564',
			@CreerRIO  = 0

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2013-08-28		Donald Huppé						Création du service		
        2018-09-18      Pierre-Luc Simard                   N'est plus utilisée

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psTEMP_GenererRIOSpecial] 
(
	@vcUserID varchar(255),
	@ConventionNo VARCHAR(15),
	@CreerRIO  bit = 0
)
AS
BEGIN
	SELECT 1/0
    /*
    DECLARE
		@ConventionID INT,
		@UnitID int,
		@Souscripteur varchar(255),
		@SubscriberID int,
		@ConnectID int,
		@FaireRIO int,
		@dtDateDuJour datetime,
		@i INT,
		@IErreur int,	
		@cMessage varchar(500),
		@INM MONEY,
		@ITR MONEY,
		@INS MONEY,
		@ISPlus MONEY,
		@IBC MONEY,
		@IST MONEY,
		@MIM MONEY,
		@ICQ MONEY,
		@IMQ MONEY,
		@III MONEY,
		@IIQ MONEY,
		@IQI MONEY,
		@SoldeCotisation MONEY,
		@SoldeSCEE MONEY,
		@SoldeConvOper MONEY

	if not exists (select 1 from sysobjects where Name = 'tblTEMP_RIOSpecial')
		begin
		create table tblTEMP_RIOSpecial (conventionno varchar(20), UserID varchar(255)) --drop table tblTEMP_TIOIQEE
		end

	-- On laisse un trace dans une table lors d'une demande demander de créer un RIO 
	IF 	@CreerRIO = 0
		begin
		delete from tblTEMP_RIOSpecial 
		insert into tblTEMP_RIOSpecial VALUES (@ConventionNo, @vcUserID)
		end

	set @cMessage = ''
	set @FaireRIO = 1
	set @IErreur = 0

	SELECT 
		@ConventionID = ConventionID,
		@Souscripteur = HS.FirstName + ' ' + HS.LastName,
		@SubscriberID = C.SubscriberID
		 
	FROM dbo.Un_Convention C
	JOIN dbo.Mo_Human HS ON C.SubscriberID = HS.HumanID
	WHERE ConventionNo = @ConventionNo and PlanID <> 4 -- select * from un_plan
	
	-- vérifier que la convention existe
	if ISNULL(@ConventionID,0) = 0
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Convention COLLECTIVE non trouvée.'
		set @FaireRIO = 0
		goto abort
		END

	if ISNULL(@ConventionID,0) <> 0
	
	BEGIN
	
		-- Vérifier s'il y a des soldes
		select 
			@SoldeCotisation = SUM(ct.Cotisation + ct.Fee)
		FROM dbo.Un_Convention c
		JOIN dbo.Un_Unit u ON c.ConventionID = u.ConventionID
		join Un_Cotisation ct ON u.UnitID = ct.UnitID
		where c.ConventionID = @ConventionID
		
		SELECT 
			@SoldeSCEE = sum(fcesg + facesg + fCLB)
		FROM Un_CESP ce
		JOIN dbo.Un_Convention c ON ce.ConventionID = c.ConventionID
		WHERE c.ConventionID = @ConventionID
		
		SELECT @SoldeConvOper =  SUM(co.ConventionOperAmount)
		FROM dbo.Un_Convention c
		join Un_ConventionOper co ON c.ConventionID = co.ConventionID
		WHERE c.ConventionID = @ConventionID

		-- Vérification des soldes de cotisations + frais
		IF @SoldeCotisation = 0 and @SoldeSCEE = 0 and @SoldeConvOper = 0

			BEGIN
			set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Aucun solde dans la convention.'
			set @FaireRIO = 0
			goto abort
			END
	
		-- Vérification des soldes négatifs
		SELECT 
			--c.ConventionNo,
			@INM = sum(CASE WHEN co.ConventionOperTypeID = 'INM' THEN co.ConventionOperAmount ELSE 0 END),
			@ITR = sum(CASE WHEN co.ConventionOperTypeID = 'ITR' THEN co.ConventionOperAmount ELSE 0 END),
			@INS = sum(CASE WHEN co.ConventionOperTypeID = 'INS' THEN co.ConventionOperAmount ELSE 0 END),
			@ISPlus = sum(CASE WHEN co.ConventionOperTypeID = 'IS+' THEN co.ConventionOperAmount ELSE 0 END),
			@IBC = sum(CASE WHEN co.ConventionOperTypeID = 'IBC' THEN co.ConventionOperAmount ELSE 0 END),
			@IST = sum(CASE WHEN co.ConventionOperTypeID = 'IST' THEN co.ConventionOperAmount ELSE 0 END),
			@MIM = sum(CASE WHEN co.ConventionOperTypeID = 'MIM' THEN co.ConventionOperAmount ELSE 0 END),
			@ICQ = sum(CASE WHEN co.ConventionOperTypeID = 'ICQ' THEN co.ConventionOperAmount ELSE 0 END),
			@IMQ = sum(CASE WHEN co.ConventionOperTypeID = 'IMQ' THEN co.ConventionOperAmount ELSE 0 END),
			@III = sum(CASE WHEN co.ConventionOperTypeID = 'III' THEN co.ConventionOperAmount ELSE 0 END),
			@IIQ = sum(CASE WHEN co.ConventionOperTypeID = 'IIQ' THEN co.ConventionOperAmount ELSE 0 END),
			@IQI = sum(CASE WHEN co.ConventionOperTypeID = 'IQI' THEN co.ConventionOperAmount ELSE 0 END)
		from 
			Un_Convention c
			JOIN Un_ConventionOper co ON c.Conventionid = co.ConventionID
			JOIN Un_Oper o ON co.OperID = o.OperID
		WHERE 
			c.ConventionID = @ConventionID
		GROUP by 
			c.ConventionNo

		IF @INM<0 OR @ITR<0 OR @INS<0 OR @ISPlus<0 OR @IBC<0 OR @IST<0 OR @MIM<0 OR @ICQ<0 OR @IMQ<0 OR @III<0 OR @IIQ<0 OR @IQI< 0

			BEGIN
			set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Rendement négatifs. ARI à Faire dabord. Cliquez sur la convention.'
			set @FaireRIO = 0
			--goto abort
			END

	END	
		
	-- vérification que l'usager à le droit
	if @vcUserID not like '%dhuppe%' and @vcUserID not like '%bjeannotte%' and @vcUserID not like '%mhpoirier%' and @vcUserID not like '%menicolas%'  
		begin
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Usager non autorisé : ' + @vcUserID
		set @FaireRIO = 0
		--goto abort
		end

	if @CreerRIO = 1 and not exists(SELECT 1 from tblTEMP_RIOSpecial where conventionno = @ConventionNo)
		begin
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Attention. Demandez d''abord le rapport demander la création du RIO !'
		set @FaireRIO = 0
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
		set @FaireRIO = 0
		END

	if @FaireRIO = 1 and @CreerRIO = 0
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Vous pouvez créer le RIO.'
		END		
	
	if @FaireRIO = 1 and @CreerRIO = 1
		begin	
		
		set @dtDateDuJour = getdate()

		-- Faire le RIO pour chaque groupe d'unité de la convention

		DECLARE MyCursor CURSOR FOR

			SELECT unitid FROM dbo.Un_Unit where ConventionID = @ConventionID

		OPEN MyCursor
		FETCH NEXT FROM MyCursor INTO @UnitID

		WHILE @@FETCH_STATUS = 0
		BEGIN
			
			EXECUTE @i = [dbo].[psOPER_CreerOperationRIO]
										@iID_Connexion = @ConnectID, --ID de connection de l'usager
							/**/		@iID_Convention = @ConventionID, --ID de la convention Source (Collective)
							/**/		@iID_Unite = @UnitID, -- ID de l'unite Source
										@dtDateEstimeeRembInt = @dtDateDuJour, --Date estimée de remboursement
										@dtDateConvention = @dtDateDuJour,-- Date de convention,
							/**/		@iID_Convention_Destination = NULL,
							/**/		@vcType_Conversion = 'RIO',
										@tiByPassFrais = 1 -- ne pas générer de frais (1)
			if @i <> 1
			begin
				set @IErreur = 1
			end
			--select @i
			FETCH NEXT FROM MyCursor INTO @UnitID
		END
		CLOSE MyCursor
		DEALLOCATE MyCursor

		delete from tblTEMP_RIOSpecial where conventionno = @ConventionNo

		IF  (@IErreur = 1)
			BEGIN
			set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Une erreur est survenue à la création du RIO. Avisez les TI.'
			END
		else
			BEGIN
			set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'RIO créé avec succès.'
			END	

		end
	
	abort:
	
	select 
		LeMessage = MAX(LeMessage),
		ConventionNo = MAX(ConventionNo),
		Souscripteur = max(Souscripteur),
		SubscriberID = MAX(SubscriberID)
	from (
		
		SELECT 
			LeMessage = NULL,
			C.ConventionNo,
			Souscripteur = HS.FirstName + ' ' + HS.LastName,
			SubscriberID = C.SubscriberID
		FROM dbo.Un_Convention C
		JOIN dbo.Mo_Human HS ON C.SubscriberID = HS.HumanID
		WHERE ConventionNo = @ConventionNo
		
		Union
		
		SELECT 
			LeMessage = @cMessage,
			ConventionNo = NULL,
			Souscripteur = NULL,
			SubscriberID = NULL
		) V
*/	
END