/****************************************************************************************************
Copyrights (c) 2014 Gestion Universitas inc
Code du service:	psCONV_OutilSSRSEnregistrerPrevalidationPCEE
Nom du service:		Vérifier et mettre à jour les prévalidations des convention pour la SCEE.
But:						Mettre à jour les prévalidations des bénéficiaires, des souscripteurs et des convention, les annexes B, ainsi que les cases pour les demandes au PCEE
Facette:					CONV

Paramètres d’entrée	:	Paramètre						Description
									--------------------------	-----------------------------------------------------------------
		  							ConventionID					Identifiant unique de la convention à traiter. 
									BeneficiaryID					Identifiant unique de la convention à traiter. 
									SubscriberID					Identifiant unique de la convention à traiter. 																		

Exemple d’appel: exec	
	psCONV_OutilSSRSEnregistrerPrevalidationPCEE  
						@ConventionNo ='U-20091203068' -- Convention
						, @bFaireMAJ = 0
						, @SCEEFormulaire93Recu = NULL
						, @SCEEFormulaire93SCEERefusee = NULL
						, @SCEEFormulaire93SCEEPlusRefusee = NULL
						, @SCEEFormulaire93BECRefuse = NULL
						, @SCEEAnnexeBTuteurRecue = NULL
						, @SCEEAnnexeBPRespRecue = NULL	

	psCONV_OutilSSRSEnregistrerPrevalidationPCEE  
						@ConventionNo ='U-20091203068' -- Convention
						, @bFaireMAJ = 1
						, @SCEEFormulaire93Recu = 1
						, @SCEEFormulaire93SCEERefusee = 0
						, @SCEEFormulaire93SCEEPlusRefusee = 0
						, @SCEEFormulaire93BECRefuse = 0
						, @SCEEAnnexeBTuteurRecue = 1
						, @SCEEAnnexeBPRespRecue = 1	
							
Paramètres de sortie:		Table						Champ							Description
		  							-------------------------	--------------------------- 	---------------------------------
									S/O							iCode_Retour					Code de retour standard

Historique des modifications:
						2014-10-30	Pierre-Luc Simard		Création du service
						2014-11-11	Pierre-Luc Simard		Ajout de la gestion du BEC
	
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_OutilSSRSEnregistrerPrevalidationPCEE] (
	--@ConnectID AS INT = NULL, 
	@ConventionNo varchar(25),
	@bFaireMAJ bit = 0,
	@SCEEFormulaire93Recu INT = NULL,
	@SCEEFormulaire93SCEERefusee INT = NULL,
	@SCEEFormulaire93SCEEPlusRefusee INT = NULL,
	@SCEEFormulaire93BECRefuse INT = NULL,
	--@SCEEAnnexeBTuteurRequise,
	@SCEEAnnexeBTuteurRecue INT = NULL,
	--@SCEEAnnexeBPRespRequise,
	@SCEEAnnexeBPRespRecue INT = NULL
	)
AS
BEGIN

	declare
		@cMessage varchar(500),
		@FaireMAJ int,
		@ConventionID INT

	select @ConventionID = ConventionID FROM dbo.Un_Convention where ConventionNo = @ConventionNo

	if not exists (select 1 from sysobjects where Name = 'tblTEMP_PrevalidationPCEE')
		begin
		create table tblTEMP_PrevalidationPCEE (conventionno varchar(20), DateInsert datetime)
		end

	-- On laisse un trace dans une table lors d'une demande . Afin de vérifier ultérieurement, lors d'une demande de maj, 
	IF 	(@bFaireMAJ = 0)
		begin
		delete from tblTEMP_PrevalidationPCEE where conventionno <> @ConventionNo 
		insert into tblTEMP_PrevalidationPCEE VALUES (@ConventionNo, getdate())
		end

	set @cMessage = ''
	set @FaireMAJ = 1

	IF  (@bFaireMAJ <> 0)
		AND not exists (SELECT 1 from tblTEMP_PrevalidationPCEE where conventionno = @ConventionNo) 
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Attention. Demandez d''abord les Informations avant de faire la mise-à-jour.'
		set @FaireMAJ = 0
		END

	IF  
		@bFaireMAJ = 1  
		AND (
			@SCEEFormulaire93Recu = NULL AND
			@SCEEFormulaire93SCEERefusee = NULL AND
			@SCEEFormulaire93SCEEPlusRefusee = NULL AND
			@SCEEFormulaire93BECRefuse = NULL AND
			@SCEEAnnexeBTuteurRecue = NULL AND
			@SCEEAnnexeBPRespRecue = NULL
			)
		BEGIN
		set @FaireMAJ = 0
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Attention. Aucune modification demandée malgré une demande de mise à jour.'
		END

	if @bFaireMAJ = 1 and @FaireMAJ = 1
		begin

		--print '!!!!!!!!!!!!!!!!!!!!!!'

		update c SET
			C.SCEEFormulaire93Recu = ISNULL(@SCEEFormulaire93Recu, C.SCEEFormulaire93Recu),
			C.SCEEFormulaire93SCEERefusee = ISNULL(@SCEEFormulaire93SCEERefusee, C.SCEEFormulaire93SCEERefusee),
			C.SCEEFormulaire93SCEEPlusRefusee = ISNULL(@SCEEFormulaire93SCEEPlusRefusee, C.SCEEFormulaire93SCEEPlusRefusee),
			C.SCEEFormulaire93BECRefuse = ISNULL(@SCEEFormulaire93BECRefuse, C.SCEEFormulaire93BECRefuse),
			--C.SCEEAnnexeBTuteurRequise,
			C.SCEEAnnexeBTuteurRecue = ISNULL(@SCEEAnnexeBTuteurRecue, C.SCEEAnnexeBTuteurRecue),
			--C.SCEEAnnexeBPRespRequise,
			C.SCEEAnnexeBPRespRecue = ISNULL(@SCEEAnnexeBPRespRecue, C.SCEEAnnexeBPRespRecue)
		FROM dbo.Un_Convention c
		where c.ConventionNo = @ConventionNo

		EXEC psCONV_EnregistrerPrevalidationPCEE 2, @ConventionID, NULL, NULL, NULL
		exec TT_UN_CESPOfConventions 
			@ConnectID		=1,	
			@BeneficiaryID	=0,	
			@SubscriberID	=0,	
			@ConventionID	=@ConventionID
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Mise-à-jour complétée'

		delete from tblTEMP_PrevalidationPCEE where conventionno = @ConventionNo

		end

	SELECT	
		LeMessage = @cMessage,
		CSS.ConventionStateID,
		C.ConventionID,
		C.ConventionNo,
		C.BeneficiaryID,
		C.SubscriberID,
		C.bFormulaireRecu,
		C.bCESGRequested,
		C.bACESGRequested,
		C.bCLBRequested,
		CtiCESPState = C.tiCESPState,
		BtiCESPState = B.tiCESPState,
		StiCESPState = S.tiCESPState,
		C.SCEEFormulaire93Recu,
		C.SCEEFormulaire93SCEERefusee,
		C.SCEEFormulaire93SCEEPlusRefusee,
		C.SCEEFormulaire93BECRefuse,
		C.SCEEAnnexeBTuteurRequise,
		C.SCEEAnnexeBTuteurRecue,
		C.SCEEAnnexeBPRespRequise,
		C.SCEEAnnexeBPRespRecue,
		SLastName = SH.LastName,
		SFirstName = SH.FirstName,
		SSocialNumber = SH.SocialNumber,
		B.iTutorID, 
		B.bTutorIsSubscriber,
		TSocialNumber = ISNULL(TuH.SocialNumber, Tu.vcEN),
		TLastName = TuH.LastName, 
		TFirstName = TuH.FirstName,
		B.bPCGIsSubscriber,
		B.vcPCGSINorEN,
		B.vcPCGFirstName,
		B.vcPCGLastName,
		B.tiPCGType,
		BenefName = hb.FirstName + ' ' + hb.LastName
		
	FROM dbo.Un_Convention C
	JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
	JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
	JOIN dbo.Mo_Human SH ON SH.HumanID = S.SubscriberID
	JOIN dbo.Mo_Human hb on c.BeneficiaryID = hb.HumanID
	LEFT JOIN Un_Tutor Tu ON Tu.iTutorID = B.iTutorID
	LEFT JOIN dbo.Mo_Human TuH ON TuH.HumanID = B.iTutorID
	LEFT JOIN (
		SELECT
			CS.ConventionID ,
			CCS.StartDate ,
			CS.ConventionStateID
		FROM Un_ConventionConventionState CS
		JOIN (
			SELECT
				ConventionID ,
				StartDate = MAX(StartDate)
			FROM Un_ConventionConventionState
			--WHERE StartDate < DATEADD(d, 1, GETDATE())
			GROUP BY ConventionID
			 ) CCS ON CCS.ConventionID = CS.ConventionID
				AND CCS.StartDate = CS.StartDate 
		) CSS on C.ConventionID = CSS.ConventionID
	WHERE 
		--c.SubscriberID = 575993
		C.Conventionno = @ConventionNo
		
END


