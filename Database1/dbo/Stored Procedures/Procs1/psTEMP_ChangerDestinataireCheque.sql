/********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psTEMP_ChangerBeneficiaireCheque
Nom du service		: 
But 				: 
Facette				: TEMP

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2012-11-29		Donald Huppé						Création du service		
		2013-10-23		Donald Huppé						Ajouter AND iPayeeChangeAccepted = 0 (voir 2013-10-23)
		2014-11-21		Donald Huppé						Ajout de casamson dans les usagers autorisés
		2015-08-07		Donald Huppé						glpi 15263 : ajout de Maude Viens','Sophie Trichot','Joëlle Cloutier','Stéphanie Deroy  dans les usagers autorisés
		2015-11-20		Donald Huppé						Ajout d'usager autorisé : Annie Poirier, Valérie Lapointe Anne Nadeau, Gaétane Grondin, Kathia Tardif, Kathie Dubuc 
		2015-12-14		Pierre-Luc Simard				    JIRA BD-41 - Ajout d'usager autorisé : Constance Bourget, Mylène Gobeil, Nathalie Lafond, Marie-Ève Durou et Martine Cadorette 
        2016-07-18      Pierre-Luc Simard                   Ajout de Cristel Héon
		2016-08-29		Donald Huppé						Ajout de fmenard
		2017-03-03		Donald Huppé						Ajout de nbabin
		2017-07-07		Donald Huppé						jira ti-8543 : Ajout de Martine Larrivée et Ève Landry
		2017-09-27		Donald Huppé						jira ti-9382 : ajout de dteki
		2017-12-22		Donald Huppé						jira ti-10499 : ajout de LDrolet
		2018-04-17		Donald Huppé						Ajout de ajlemaire
        2018-05-22      Pierre-Luc Simard                   Ajout de jcouture
       
EXEC psTEMP_ChangerDestinataireCheque 'DHUPPE', '2012-11-21', 'RES', NULL, NULL, NULL
EXEC psTEMP_ChangerDestinataireCheque 'DHUPPE', '2012-11-21', 'RES', 'U-20030618021', NULL, NULL
EXEC psTEMP_ChangerDestinataireCheque 'DHUPPE', '2012-11-29', 'PAE', NULL, NULL, NULL, NULL
EXEC psTEMP_ChangerDestinataireCheque 'DHUPPE', '2012-11-29', 'PAE', '2222', NULL, NULL, NULL

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psTEMP_ChangerDestinataireCheque] 
(
	@UserID varchar(255),
	@dtOperation DATETIME,
	@vcRefType VARCHAR(10),
	@vcConventionNo VARCHAR(15) = NULL,
	@iOperationID integer = NULL,
	@HumanIDFromList int = null,
	@HumanID INT = null

)
AS
BEGIN

DECLARE 
	@QteOperation int,
	@QteHuman int,
	@nomDestinataire varchar (100),
	@Messsage varchar(500),
	@iPayeeID int,
	@FaireLeChangement int

	CREATE TABLE #tmp1( -- drop table #tmp1
		[iOperationID] [int] NOT NULL,
		[iPayeeID] [int] NOT NULL,
		[bDestHistory] [bit] NULL,
		[bCheckHistory] [bit] NULL,
		[dtOperation] [datetime] NOT NULL,
		[vcRefType] [varchar](10) NOT NULL,
		[fAmount] [decimal](38, 4) NULL,
		[vcDescription] [varchar](50) NULL,
		[vcFirstName] [varchar](50) NOT NULL,
		[vcLastName] [varchar](50) NOT NULL,
		[bIsCompany] [int] NULL,
		[vcAccount] [varchar](50) NULL,
		[iID_Regroupement_Regime] [int] NULL
	)

	INSERT INTO #tmp1
	EXEC SL_CHQ_OperByDateType @dtOperation, @vcRefType

	set @FaireLeChangement = 1
	set @QteOperation = 0
	set @QteHuman = 0
	set @Messsage = ''

	if @vcConventionNo is not null AND not exists (select 1 from #tmp1 where vcDescription = @vcConventionNo)
		begin
		set @FaireLeChangement = 0
		set @Messsage = @Messsage + ' Convention inconnue (' + @vcConventionNo +' ) à cette date pour ce type d''opération.' + CHAR(10)
		print @Messsage
		end
		
	if @iOperationID is not null AND not exists (select 1 from #tmp1 where iOperationID = @iOperationID)
		begin
		set @FaireLeChangement = 0
		set @Messsage =  @Messsage + ' OperationID inconnue (' + CAST(@iOperationID as varchar) +') à cette date pour ce type d''opération.'+ CHAR(10)
		print @Messsage
		end
		
	if @HumanIDFromList is not null and @HumanID is not null
		begin
		set @FaireLeChangement = 0
		set @Messsage =  @Messsage + ' Sélectionnez un seul humain. Soit dans la liste OU en saisir un ID.'+ CHAR(10)
		end

	set @HumanID = ISNULL(@HumanID,@HumanIDFromList)

	select @QteHuman = COUNT(*) FROM dbo.Mo_Human where HumanID = ISNULL(@HumanID,0)

	IF @QteHuman <> 1 AND @HumanID IS NOT NULL
		begin
		set @FaireLeChangement = 0
		set @Messsage = @Messsage + 'ID de destinataire inconnu.'+ CHAR(10)
		end

	if isnull(@iPayeeID,0) = ISNULL(@HumanID,0) and @HumanID is not null
		begin
		set @FaireLeChangement = 0
		set @Messsage = @Messsage +'il s''agit du même destinataire.'
		end

	if exists(select 1 from CHQ_OperationPayee where iPayeeID = @HumanID and iOperationID = @iOperationID AND iPayeeChangeAccepted = 0) -- 2013-10-23
		begin
		set @FaireLeChangement = 0
		set @Messsage = @Messsage + 'Changement de destinataire déjà effectué !!!'+ CHAR(10)
		end
	
	if @UserID 
				not like '%dhuppe%' 
				--and @UserID not like '%bjeannotte%' 
				and @UserID not like '%menicolas%'  
				and @UserID not like '%casamson%'
				and @UserID not like '%strichot%'
				and @UserID not like '%mviens%'
				and @UserID not like '%jcloutier%'
				and @UserID not like '%sderoy%'
				and @UserID not like '%anadeau%' 
				and @UserID not like '%apoirier%' 
				and @UserID not like '%ggrondin%' 
				and @UserID not like '%kdubuc%' 
				and @UserID not like '%ktardif%' 
				and @UserID not like '%vlapointe%'	
				and @UserID not like '%cbourget%'	
				and @UserID not like '%mgobeil%'	
				and @UserID not like '%nlafond%'	
				and @UserID not like '%medurou%'	
				and @UserID not like '%mcadorette%'	
                and @UserID not like '%cheon%'	
				and @UserID not like '%fmenard%'	
				and @UserID not like '%nbabin%'	
				and @UserID not like '%elandry%'
				and @UserID not like '%mlarrivee%'
				and @UserID not like '%dteki%'
				and @UserID not like '%LDrolet%'
				and @UserID not like '%ajlemaire%'
                and @UserID not like '%jcouture%'
					
				
																		
		begin
		set @FaireLeChangement = 0
		set @Messsage = @Messsage + 'Usager non autorisé.'+ CHAR(10)
		end
	
	SELECT 
		@QteOperation = COUNT(*), @iPayeeID = MAX(iPayeeID)
	from 
		#tmp1 
	where 
		1=1
		AND ((vcDescription = @vcConventionNo) OR @vcConventionNo is null)
		AND ((iOperationID = @iOperationID) OR (@iOperationID is null))

	if @FaireLeChangement = 1
		and @QteOperation = 1 and @iOperationID is not null 
		and @QteHuman = 1 and @HumanID is not null
		
		BEGIN
		
		-- Ici on ajoute le HumanID dans la table des destinataire de chèque s'il n'est pas déjà présent.
		IF NOT EXISTS (SELECT * FROM CHQ_Payee WHERE iPayeeID = @HumanID)
			begin
			INSERT INTO CHQ_Payee VALUES (@HumanID)
			end
		
		INSERT INTO CHQ_OperationPayee (
			iPayeeID, -- ID du destinataire de chèque
			iOperationID, -- ID de l'opération du module des chèques
			iPayeeChangeAccepted, -- Status du changement de destinataire (0 = indéterminé, 1 = accepté et 2 = refusé)
			dtCreated, -- Date de création du changement de destinataire
			vcReason ) -- Raison
		SELECT
			@HumanID, 
			iOperationID,
			0,
			dtOperation,
			'Demande de ' + @UserID
		FROM CHQ_Operation
		WHERE iOperationID = @iOperationID
		
		select @nomDestinataire =isnull(FirstName,'') + ' ' + isnull(LastName,'') FROM dbo.Mo_Human where HumanID = @HumanID
		
		set @Messsage = 'Changement de dest. fait pour : ' + @nomDestinataire + ' (est maintenant présent dans écran d''autoris. de chgmt. de dest.'
		
		END

	SELECT 
		[iOperationID],
		[iPayeeID],
		DestinataireActuel = isnull(h.FirstName,'') + ' ' + isnull(h.LastName,'') ,
		[bDestHistory],
		[bCheckHistory],
		[dtOperation],
		[vcRefType],
		[fAmount],
		[vcDescription],
		[vcFirstName],
		[vcLastName],
		[bIsCompany],
		[vcAccount],
		[iID_Regroupement_Regime],
		LeMessage = @Messsage
	from 
		#tmp1 t
		left join dbo.Mo_Human h on t.iPayeeID = h.HumanID
	where 
			(
				 ((vcDescription = @vcConventionNo) OR @vcConventionNo is null)
				 AND
				((iOperationID = @iOperationID) OR (@iOperationID is null))
			)
		or @FaireLeChangement = 0
	
end	

