/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service	: psTEMP_GenererARI
Nom du service		: 
But 				: 
Facette			: TEMP

Paramètres d’entrée	:   Paramètre					Description
				    --------------------------	-----------------------------------------------------------------

Exemple d’appel	:	
    exec psTEMP_GenererARI @UserID =  'mhpoirier', @vcConventionNo ='T-20121224001',@INM_c = -1 , @ModeAutomatique = 0 
    exec psTEMP_GenererARI @UserID =  'mhpoirier', @vcConventionNo ='T-20130515040' , @ModeAutomatique = 0 
    exec psTEMP_GenererARI @UserID =  'dd', @vcConventionNo ='T-20121224001' , @ModeAutomatique = 0 

    select *
    FROM Un_ConventionOperType
    where ConventionOperTypeID IN ('ICQ','IMQ','IIQ','III','IQI','MIM','INM','IS+','INS','IBC','ITR','IST')

    INM : Rendements sur montant souscrit
    ITR : Rendements (Transfert IN)
    INS : Rendements sur la SCEE
    ISPlus : Rendements sur la SCEE+
    IBC : Rendements sur le BEC
    IST : Rendements sur les rendements de PCEE provenant d'un transfert IN
    MIM : Intérêts reçus de RQ
    ICQ : Rendements sur le crédit de base du Québec
    IMQ : Rendements sur la majoration du Québec
    III : Rendements sur rendements accumulés de l'IQÉÉ provenant d'un transfert IN
    IIQ : Rendements sur l'intérêt reçu de RQ
    IQI : Rendements accumulés de l'IQÉÉ provenant d'un transfert IN

ATTENTION! POUR QUE ÇA FONCTIONNE, L'UTILISATEUR DOIT AVOIR ACCÈS À SSRS, VIA LE GROUPE ALL_USERGROUPS, DANS L'AD.

Paramètres de sortie:	

Historique des modifications:
    Date        Programmeur             Description
    ----------  --------------------    -----------------------------------------------------
    2012-08-13  Donald Huppé            Création du service		
    2012-09-05  Donald Huppé            Correction de IS+					
    2013-08-02  Donald Huppé            glpi 9993 : ajout nom sousc + correctino couleur IBC
    2013-10-15  Donald Huppé            glpi 10006 : Donner accès à faire des ARI avec EAFB < 50 
                                        dans Régime T à Bernard Jeannotte et Marie-Hélène Poirier
	2015-02-24	Donald Huppé            Enlever YConte et inscrire jtessier
	2015-10-01	Steve Picard            Accès en DEV
    2017-12-29  Pierre-Luc Simard       Jira TI-10623: Ajout de jchicoine 
	2018-11-21	Donald Huppé			Ajout de chuppe et igirard
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psTEMP_GenererARI] 
(
	@UserID varchar(255),
	@vcConventionNo VARCHAR(15),
	@INM_c MONEY = 0.0,
	@ITR_c MONEY = 0.0,
	@INS_c MONEY = 0.0,
	@ISPlus_c MONEY = 0.0,
	@IBC_c MONEY = 0.0,
	@IST_c MONEY = 0.0,
	@MIM_c MONEY = 0.0,
	@ICQ_c MONEY = 0.0,
	@IMQ_c MONEY = 0.0,
	@III_c MONEY = 0.0,
	@IIQ_c MONEY = 0.0,
	@IQI_c MONEY = 0.0,
	@EAFB_c MONEY = 0.0,
	--@dtDateOperARI datetime = null,
	@ModeAutomatique bit
)
AS
BEGIN
	declare

	@FaireARI int,

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
	@EAFB MONEY,

	@EAFB_cToCome money,

	@iID_Convention INT,
	@dtDateOperARI DATETIME,
	@iID_Operation INT,
	@UserHasRightToMakeARI bit = 0,
	@SouscNom varchar(255),
	@ConventionRIO int

	set @vcConventionNo = ltrim(rtrim(UPPER(@vcConventionNo)))

	if @UserID like '%dhuppe%' or @UserID like '%jtessier%' or @UserID like '%mcbreton%' or @UserID like '%jchicoine%'
		-- ceux-ci on des accès limités - glpi 10006
		--or @UserID like '%mhpoirier%' or @UserID like '%bjeannotte%'
		or @UserID like '%chuppe%'
		or @UserID like '%igirard%'
		-- accorde le droit pour tous si non en PROD
		or NOT @@SERVERNAME IN ('SRVSQL12', 'SRVSQL25', 'SRVSQL22', 'SRVSQL10')
		begin
		set @UserHasRightToMakeARI = 1
		end

	SET @dtDateOperARI = LEFT(CONVERT(VARCHAR, getdate(), 120), 10)

	DECLARE @tblCorrectionPropose table (
			INM_c MONEY,
			ITR_c MONEY,
			INS_c MONEY,
			ISPlus_c MONEY,
			IBC_c MONEY,
			IST_c MONEY,
			MIM_c MONEY,
			ICQ_c MONEY,
			IMQ_c MONEY,
			III_c MONEY,
			IIQ_c MONEY,
			IQI_c MONEY,
			EAFB_c MONEY)

	DECLARE @cMessage varchar(255)
	set @cMessage = ''
	set @FaireARI = 0

	SELECT DISTINCT
		@iID_Convention = C.ConventionID,
		@SouscNom = hs.LastName + ', ' + hs.FirstName,
		@ConventionRIO = case when R.ConventionID is not NULL then 1 ELSE 0 end
	FROM 
		Un_Convention C
		JOIN dbo.Mo_Human hs ON c.SubscriberID = hs.HumanID
		left join (
			SELECT 
				DISTINCT c1.ConventionID
			from 
				Un_Convention c1
				join tblOPER_OperationsRIO r1 ON r1.iID_Convention_Destination = C1.ConventionID and r1.bRIO_Annulee = 0 and r1.bRIO_QuiAnnule = 0 and r1.OperTypeID = 'RIO'
			where 
				c1.ConventionNo = @vcConventionNo
		)r ON r.ConventionID = C.ConventionID
	WHERE 
		C.ConventionNo = @vcConventionNo

	if @SouscNom is null --not exists(SELECT 1 FROM dbo.Un_Convention where conventionno = @vcConventionNo )
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end + '****** Convention inconnue **********'
		set @FaireARI = 0
		goto EnvoyerInfo
		END

	-- Pour certain usagers, seul le mode automatique est autorisé. alors s'il y a un montant <> 0 passé en paramètre, on averti l'usager
	if (@INM_c<>0 OR @ITR_c<>0 OR @INS_c<>0 OR @ISPlus_c<>0 OR @IBC_c<>0 OR @IST_c<>0 OR @MIM_c<>0 OR @ICQ_c<>0 OR @IMQ_c<>0 OR @III_c<>0 OR @IIQ_c<>0 OR @IQI_c <> 0 or @EAFB_c<>0) 
		and (@UserID like '%mhpoirier%' OR @UserID like '%bjeannotte%')
		begin
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  
						'Mode automatique OBLIGATOIRE pour l''usager (' + @UserID + '). Mettez tous les montants à 0.'
		set @FaireARI = 0
		goto EnvoyerInfo
		end		

	if @UserHasRightToMakeARI = 1
		begin 

		if not exists (select 1 from sysobjects where Name = 'tblTEMP_ARI_Auto')
			begin
			create table tblTEMP_ARI_Auto (UserID varchar(255), conventionno varchar(20), DateInsert datetime) --drop table tblTEMP_ARI_Auto
			end

		IF 	(@ModeAutomatique = 0)
			begin
			delete from tblTEMP_ARI_Auto where UserID =  @UserID
			insert into tblTEMP_ARI_Auto VALUES (@UserID,@vcConventionNo, getdate())
			end

		insert INTO @tblCorrectionPropose
		exec psTEMP_ObtenirCorrectionARI @vcConventionNo , @dtDateOperARI

		if @ModeAutomatique > 0
			begin
			select
				@INM_c = INM_c,
				@ITR_c = ITR_c,
				@INS_c = INS_c,
				@ISPlus_c = ISPlus_c,
				@IBC_c = IBC_c,
				@IST_c = IST_c,
				@MIM_c = MIM_c,
				@ICQ_c = ICQ_c,
				@IMQ_c = IMQ_c,
				@III_c = III_c,
				@IIQ_c = IIQ_c,
				@IQI_c = IQI_c,
				@EAFB_c = EAFB_c
			from @tblCorrectionPropose
			end

		END --@UserHasRightToMakeARI = 1

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
		c.ConventionNo = @vcConventionNo
		AND o.OperDate <= @dtDateOperARI
	GROUP by 
		c.ConventionNo

	IF @INM_c<>0 OR @ITR_c<>0 OR @INS_c<>0 OR @ISPlus_c<>0 OR @IBC_c<>0 OR @IST_c<>0 OR @MIM_c<>0 OR @ICQ_c<>0 OR @IMQ_c<>0 OR @III_c<>0 OR @IIQ_c<>0 OR @IQI_c	<> 0
		BEGIN
		set @FaireARI = 1
		END

	if @ModeAutomatique > 0 and not exists(SELECT 1 from tblTEMP_ARI_Auto where conventionno = @vcConventionNo and UserID = @UserID) and @UserHasRightToMakeARI = 1
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end + 'Demandez d''abord les soldes sans mode Automatique.'
		set @FaireARI = 0
		END

	IF (@EAFB_c+@INM_c+@ITR_c+@INS_c+@ISPlus_c+@IBC_c+@IST_c+@MIM_c+@ICQ_c+@IMQ_c+@III_c+@IIQ_c+@IQI_c) <> 0
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end + 'Le total de la correction ARI ne donne pas 0.'
		set @FaireARI = 0
		END

	IF isnull(@INM_c,0) > 0 and (@INM + @INM_c) <> 0
		BEGIN
		set @cMessage = @cMessage +  ' Correction INM ne donne pas 0.'
		set @FaireARI = 0
		END	

	IF isnull(@ITR_c,0) < 0 and (@ITR + @ITR_c) < 0
		BEGIN
		set @cMessage = @cMessage +  ' Trop de $ puisé dans ITR.'
		set @FaireARI = 0
		END	

	IF isnull(@INS_c,0) < 0 and (@INS + @INS_c) < 0
		BEGIN
		set @cMessage = @cMessage +  ' Trop de $ puisé dans INS.'
		set @FaireARI = 0
		END	

	IF isnull(@ISPlus_c,0) < 0 and (@ISPlus + @ISPlus_c) < 0
		BEGIN
		set @cMessage = @cMessage +  ' Trop de $ puisé dans IS+.'
		set @FaireARI = 0
		END	

	IF isnull(@IBC_c,0) < 0 and (@IBC + @IBC_c) < 0
		BEGIN
		set @cMessage = @cMessage +  ' Trop de $ puisé dans IBC.'
		set @FaireARI = 0
		END	

	IF isnull(@IST_c,0) < 0 and (@IST + @IST_c) < 0
		BEGIN
		set @cMessage = @cMessage +  ' Trop de $ puisé dans IST.'
		set @FaireARI = 0
		END			

	IF isnull(@MIM_c,0) < 0 and (@MIM + @MIM_c) < 0
		BEGIN
		set @cMessage = @cMessage +  ' Trop de $ puisé dans MIM.'
		set @FaireARI = 0
		END		

	IF isnull(@ICQ_c,0) < 0 and (@ICQ + @ICQ_c) < 0
		BEGIN
		set @cMessage = @cMessage +  ' Trop de $ puisé dans ICQ.'
		set @FaireARI = 0
		END		

	IF isnull(@ICQ_c,0) > 0 and (@ICQ + @ICQ_c) > 0
		BEGIN
		set @cMessage = @cMessage +  ' Trop de $ mis dans ICQ.'
		set @FaireARI = 0
		END		

	IF isnull(@IMQ_c,0) < 0 and (@IMQ + @IMQ_c) < 0
		BEGIN
		set @cMessage = @cMessage +  ' Trop de $ puisé dans IMQ.'
		set @FaireARI = 0
		END		

	IF isnull(@IMQ_c,0) > 0 and (@IMQ + @IMQ_c) > 0
		BEGIN
		set @cMessage = @cMessage +  ' Trop de $ mis dans IMQ.'
		set @FaireARI = 0
		END		

	IF isnull(@III_c,0) < 0 and (@III + @III_c) < 0
		BEGIN
		set @cMessage = @cMessage +  ' Trop de $ puisé dans III.'
		set @FaireARI = 0
		END	

	IF isnull(@IIQ_c,0) > 0 and (@IIQ + @IIQ_c) > 0
		BEGIN
		set @cMessage = @cMessage +  ' Trop de $ mis dans IIQ.'
		set @FaireARI = 0
		END	

	IF isnull(@IQI_c,0) < 0 and (@IQI + @IQI_c) < 0
		BEGIN
		set @cMessage = @cMessage +  ' Trop de $ puisé dans IQI.'
		set @FaireARI = 0
		END		

	IF isnull(@IQI_c,0) > 0 and (@IQI + @IQI_c) > 0
		BEGIN
		set @cMessage = @cMessage +  ' Trop de $ mis dans IQI.'
		set @FaireARI = 0
		END		

/* -- J'enlève cette validation le 2013-10-15 car je crois qu'elle n'est pas nécessaire.
	IF EXISTS (
		SELECT 
			C.ConventionNo
		FROM Un_ConventionOper CO
		JOIN Un_Oper O ON O.OperID = CO.OperID
		JOIN dbo.Un_Convention C ON C.ConventionID = CO.ConventionID
		WHERE C.ConventionID = @iID_Convention
		AND O.OperTypeID = 'ARI'
		AND LEFT(CONVERT(VARCHAR, O.OperDate, 120), 10) = @dtDateOperARI
		GROUP BY C.ConventionNo
		)
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  
						'ARI déjà créé aujourd''hui.'
		set @FaireARI = 0
		END
*/

	if @UserHasRightToMakeARI = 0
		begin
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  
						'Usager non autorisé : ' + @UserID
		set @FaireARI = 0
		end

	if @ConventionRIO = 0 and (@UserID like '%mhpoirier%' OR @UserID like '%bjeannotte%')
		begin
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  
						'Convention NON issue d''un RIO. ARI non autorisé. À faire par la comptabilité.'
		set @FaireARI = 0
		end	

	----------------------------------------------------------------------
	select @EAFB_c = EAFB_c from @tblCorrectionPropose
	if @EAFB_c <= -50 and (@UserID like '%mhpoirier%' OR @UserID like '%bjeannotte%')
		begin
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  
						'Utilisation du compte EAFB > 50$. ARI non autorisé. À faire par la comptabilité.'
		set @FaireARI = 0
		end	
	-----------------------------------------------------------------------------

--@cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end + 
	IF @FaireARI = 1
		BEGIN	

		-- Créer la trabsaction ARI
		EXECUTE @iID_Operation = dbo.SP_IU_UN_Oper 2, 0, 'ARI', @dtDateOperARI

		IF @EAFB_c <> 0
			BEGIN
			INSERT INTO Un_OtherAccountOper(OperID,OtherAccountOperAmount) VALUES (@iID_Operation,@EAFB_c)
			END

		IF @INM_c <> 0
			BEGIN
			INSERT INTO dbo.Un_ConventionOper (OperID,ConventionID,ConventionOperTypeID,ConventionOperAmount)
				 VALUES(@iID_Operation,@iID_Convention,'INM',@INM_c)		
			END

		IF @ITR_c <> 0
			BEGIN
			INSERT INTO dbo.Un_ConventionOper (OperID,ConventionID,ConventionOperTypeID,ConventionOperAmount)
				 VALUES(@iID_Operation,@iID_Convention,'ITR',@ITR_c)		
			END

		IF @INS_c <> 0
			BEGIN
			INSERT INTO dbo.Un_ConventionOper (OperID,ConventionID,ConventionOperTypeID,ConventionOperAmount)
				 VALUES(@iID_Operation,@iID_Convention,'INS',@INS_c)		
			END

		IF @ISPlus_c <> 0
			BEGIN
			INSERT INTO dbo.Un_ConventionOper (OperID,ConventionID,ConventionOperTypeID,ConventionOperAmount)
				 VALUES(@iID_Operation,@iID_Convention,'IS+',@ISPlus_c)		
			END

		IF @IBC_c <> 0
			BEGIN
			INSERT INTO dbo.Un_ConventionOper (OperID,ConventionID,ConventionOperTypeID,ConventionOperAmount)
				 VALUES(@iID_Operation,@iID_Convention,'IBC',@IBC_c)		
			END

		IF @IST_c <> 0
			BEGIN
			INSERT INTO dbo.Un_ConventionOper (OperID,ConventionID,ConventionOperTypeID,ConventionOperAmount)
				 VALUES(@iID_Operation,@iID_Convention,'IST',@IST_c)		
			END

		IF @MIM_c <> 0
			BEGIN
			INSERT INTO dbo.Un_ConventionOper (OperID,ConventionID,ConventionOperTypeID,ConventionOperAmount)
				 VALUES(@iID_Operation,@iID_Convention,'MIM',@MIM_c)		
			END

		IF @ICQ_c <> 0
			BEGIN
			INSERT INTO dbo.Un_ConventionOper (OperID,ConventionID,ConventionOperTypeID,ConventionOperAmount)
				 VALUES(@iID_Operation,@iID_Convention,'ICQ',@ICQ_c)		
			END

		IF @IMQ_c <> 0
			BEGIN
			INSERT INTO dbo.Un_ConventionOper (OperID,ConventionID,ConventionOperTypeID,ConventionOperAmount)
				 VALUES(@iID_Operation,@iID_Convention,'IMQ',@IMQ_c)		
			END

		IF @III_c <> 0
			BEGIN
			INSERT INTO dbo.Un_ConventionOper (OperID,ConventionID,ConventionOperTypeID,ConventionOperAmount)
				 VALUES(@iID_Operation,@iID_Convention,'III',@III_c)		
			END

		IF @IIQ_c <> 0
			BEGIN
			INSERT INTO dbo.Un_ConventionOper (OperID,ConventionID,ConventionOperTypeID,ConventionOperAmount)
				 VALUES(@iID_Operation,@iID_Convention,'IIQ',@IIQ_c)		
			END

		IF @IQI_c <> 0
			BEGIN
			INSERT INTO dbo.Un_ConventionOper (OperID,ConventionID,ConventionOperTypeID,ConventionOperAmount)
				 VALUES(@iID_Operation,@iID_Convention,'IQI',@IQI_c)		
			END

		set @cMessage = @cMessage +  'ARI créé.'

		set @INM_c = 0.0
		set @ITR_c = 0.0
		set @INS_c  = 0.0
		set @ISPlus_c  = 0.0
		set @IBC_c  = 0.0
		set @IST_c  = 0.0
		set @MIM_c  = 0.0
		set @ICQ_c  = 0.0
		set @IMQ_c  = 0.0
		set @III_c  = 0.0
		set @IIQ_c  = 0.0
		set @IQI_c  = 0.0
		set @EAFB_c  = 0.0

		DELETE FROM @tblCorrectionPropose			

		END

	Delete from tblTEMP_ARI_Auto where UserID =  @UserID and conventionno <> @vcConventionNo

	EnvoyerInfo:

	SELECT 
		Ligne = '1-Solde',
		cMessage = @cMessage,
		c.ConventionNo,
		INM = sum(CASE WHEN co.ConventionOperTypeID = 'INM' THEN co.ConventionOperAmount ELSE 0 END),
		ITR = sum(CASE WHEN co.ConventionOperTypeID = 'ITR' THEN co.ConventionOperAmount ELSE 0 END),
		INS = sum(CASE WHEN co.ConventionOperTypeID = 'INS' THEN co.ConventionOperAmount ELSE 0 END),
		ISPlus = sum(CASE WHEN co.ConventionOperTypeID = 'IS+' THEN co.ConventionOperAmount ELSE 0 END),
		IBC = sum(CASE WHEN co.ConventionOperTypeID = 'IBC' THEN co.ConventionOperAmount ELSE 0 END),
		IST = sum(CASE WHEN co.ConventionOperTypeID = 'IST' THEN co.ConventionOperAmount ELSE 0 END),
		MIM = sum(CASE WHEN co.ConventionOperTypeID = 'MIM' THEN co.ConventionOperAmount ELSE 0 END),
		ICQ = sum(CASE WHEN co.ConventionOperTypeID = 'ICQ' THEN co.ConventionOperAmount ELSE 0 END),
		IMQ = sum(CASE WHEN co.ConventionOperTypeID = 'IMQ' THEN co.ConventionOperAmount ELSE 0 END),
		III = sum(CASE WHEN co.ConventionOperTypeID = 'III' THEN co.ConventionOperAmount ELSE 0 END),
		IIQ = sum(CASE WHEN co.ConventionOperTypeID = 'IIQ' THEN co.ConventionOperAmount ELSE 0 END),
		IQI = sum(CASE WHEN co.ConventionOperTypeID = 'IQI' THEN co.ConventionOperAmount ELSE 0 END),
		EAFB = 0,
		SouscNom = @SouscNom
	from 
		Un_Convention c
		JOIN Un_ConventionOper co ON c.Conventionid = co.ConventionID
		JOIN Un_Oper o ON co.OperID = o.OperID
	WHERE 
		c.ConventionNo = @vcConventionNo
		AND o.OperDate <= @dtDateOperARI
	GROUP by 
		c.ConventionNo

	UNION

	select
		Ligne = '2-ARI proposé',
		cMessage = @cMessage,
		ConventionNo = @vcConventionNo,
		INM_c,
		ITR_c,
		INS_c,
		ISPlus_c,
		IBC_c,
		IST_c,
		MIM_c,
		ICQ_c,
		IMQ_c,
		III_c,
		IIQ_c,
		IQI_c,
		EAFB_c,
		SouscNom = @SouscNom
	from @tblCorrectionPropose
	JOIN dbo.Un_Convention c ON c.ConventionNo = @vcConventionNo

	UNION

	select
		Ligne = NULL,
		cMessage = @cMessage,
		ConventionNo = NULL,
		INM_c = NULL,
		ITR_c = NULL,
		INS_c = NULL,
		ISPlus_c = NULL,
		IBC_c = NULL,
		IST_c = NULL,
		MIM_c = NULL,
		ICQ_c = NULL,
		IMQ_c = NULL,
		III_c = NULL,
		IIQ_c = NULL,
		IQI_c = NULL,
		EAFB_c = NULL,
		SouscNom = NULL

END