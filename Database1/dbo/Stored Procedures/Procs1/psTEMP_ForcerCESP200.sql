/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psTEMP_ForcerCESP200
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
		2015-02-16		Donald Huppé						Création du service		
		2015-08-03		Donald Huppé						Ajustement de la prgrammation des message et laisser créer des 200 pour des conventions fermées (Demande de F. Ménard)

EXEC psTEMP_ForcerCESP200 241711, 1, 'dhuppe'

exec IU_UN_ReSendBeneficiaryCESP200 374382
SELECT * from Un_CESP200 where HumanID = 241711
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psTEMP_ForcerCESP200]
(
	
	@HumanID INT = null
	,@Forcer200 int = null
	,@UserID varchar(255) = null

)
AS
BEGIN

	--set @humanid = 575993

	DECLARE @cMessage varchar(255)
	set @cMessage = ''

	declare @Forcer200Ok int
	set @Forcer200Ok = 1

	declare @iExecResult int, @ConventionID int
	declare @list table (ConventionID int)
	declare @listOrError table (iExecResult int, ConventionID int)
	declare @listOfSuccess table (iExecResult int, ConventionID int)

	declare @BeneficiaryID int
	declare @SubscriberID int

	select @BeneficiaryID = BeneficiaryID FROM dbo.Un_Beneficiary where BeneficiaryID = @HumanID
	select @SubscriberID = SubscriberID FROM dbo.Un_Subscriber where SubscriberID = @HumanID

	if not exists (select 1 from sysobjects where Name = 'tblTEMP_forcer200')
		begin
		create table tblTEMP_forcer200 (humanID int, UserID varchar(255)) -- drop table tblTEMP_forcer200
		end

	if @Forcer200 = 0
		BEGIN
		delete from tblTEMP_forcer200 where UserID = @UserID
		insert into tblTEMP_forcer200 values (@HumanID, @UserID)
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end + 'Vous pouvez forcer les 200.'
		END

	if @Forcer200 > 0 and not exists(SELECT 1 from tblTEMP_forcer200 where humanID = @HumanID and UserID = @UserID)
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end + 'Demandez d''abord sans forcer les 200.'
		set @Forcer200Ok = 0
		END

	if @Forcer200 = 1 and @Forcer200Ok = 1
	BEGIN

		insert into @list(ConventionID) 
			SELECT DISTINCT c.ConventionID
			FROM dbo.Un_Convention c
			JOIN dbo.Mo_Human hb on c.BeneficiaryID = hb.HumanID
			JOIN tblGENE_Adresse ab ON hb.AdrID = ab.iID_Adresse
			JOIN dbo.Mo_Human hs on c.SubscriberID = hs.HumanID
			JOIN tblGENE_Adresse ass ON hs.AdrID = ass.iID_Adresse  
			JOIN (
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
						--where startDate < DATEADD(d,1 ,@DateFinPeriode)
						group by conventionid
						) ccs on ccs.conventionid = cs.conventionid 
							and ccs.startdate = cs.startdate 
							--and cs.ConventionStateID <> 'FRM' -- Laisser créer des 200 pour des conventions fermées (Demande de F. Ménard)
			) css on C.conventionid = css.conventionid
			where 
				C.SubscriberID = @HumanID OR C.BeneficiaryID = @HumanID

		while (select count(*) from @list) > 0
		begin
			select top 1 @ConventionID = ConventionID from @list

			if @BeneficiaryID is not NULL
				BEGIN
				EXECUTE @iExecResult = IU_UN_ReSendBeneficiaryCESP200 @ConventionID
				END

			if @SubscriberID is not NULL
				BEGIN
				EXECUTE @iExecResult = IU_UN_ReSendSubscriberCESP200 @ConventionID
				END			
	
			IF @iExecResult <= 0
			begin
			insert into @listOrError VALUES (@iExecResult,@ConventionID)
			end
			ELSE
			BEGIN
			insert into @listOfSuccess VALUES (@iExecResult,@ConventionID)
			END

			delete from @list where ConventionID = @ConventionID

		end

		if EXISTS (select 1 from @listOrError)
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end + '!!! Des erreurs sont survenues !!!'
		END

		if EXISTS (select 1 from @listOfSuccess)
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end + ' --> Des 200 ont été forcées. <--'
		END

		if not EXISTS (select 1 from @listOfSuccess)
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end + '#### Aucune 200 a été forcée. ####'
		END

		delete from tblTEMP_forcer200 where humanID = @HumanID

	END

	SELECT DISTINCT 
		C.ConventionNo
		,ConventionStateID
		,c.SubscriberID
		,NomSousc = HS.FirstName + ' ' + HS.LastName
		,c.BeneficiaryID
		,NomBenef = hb.FirstName + ' ' + hb.LastName
		,vcTransID = C2.vcTransID
		,DateEnvoi = s.dtCESPSendFile
		,tiType = C2.tiType
		,dtTransaction = C2.dtTransaction
		,vcSINorEN = C2.vcSINorEN
		,vcFirstName = C2.vcFirstName
		,vcLastName = C2.vcLastName
		,dtBirthdate = C2.dtBirthdate
		,cSex = C2.cSex
		,vcAddress1 = C2.vcAddress1
		,vcAddress2 = C2.vcAddress2
		,vcAddress3 = C2.vcAddress3
		,vcCity = C2.vcCity
		,vcStateCode = C2.vcStateCode
		,CountryID = C2.CountryID
		,vcZipCode = C2.vcZipCode
		,cLang = C2.cLang
		,vcTutorName = C2.vcTutorName		
		,C2.iCESP200ID
		,LeMessage = @cMessage
		,ErreurID = (select max(@iExecResult) from @listOrError)

	FROM dbo.Un_Convention C
	JOIN dbo.Mo_Human HS ON C.SubscriberID = HS.HumanID
	JOIN dbo.Mo_Human HB ON C.BeneficiaryID = HB.HumanID
	JOIN (
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
				--where startDate < DATEADD(d,1 ,@DateFinPeriode)
				group by conventionid
				) ccs on ccs.conventionid = cs.conventionid 
					and ccs.startdate = cs.startdate 
					--and cs.ConventionStateID in ('REE','TRA') -- je veux les convention qui ont cet état
	) css on C.conventionid = css.conventionid
	LEFT JOIN Un_CESP200 C2 on c.ConventionID = C2.ConventionID --and c.BeneficiaryID = C2.HumanID
	LEFT JOIN Un_CESPSendFile S ON S.iCESPSendFileID = C2.iCESPSendFileID
	WHERE 
		C.SubscriberID = @HumanID 
		OR C.BeneficiaryID = @HumanID
	ORDER by C.ConventionNo, C2.iCESP200ID

END


