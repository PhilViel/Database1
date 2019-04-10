/********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service        : psTEMP_LancerTraitementTIN_IQEE
Nom du service        : Procedure pour compléter les TIN d'IQEE
But                 : compléter les TIN d'IQEE
Facette                : TEMP

Paramètres d’entrée    :    Paramètre                    Description
                        --------------------------    -----------------------------------------------------------------

Exemple d’appel        :    
        exec psTEMP_LancerTraitementTIN_IQEE @UserID = 'DHUPPE', 
                                             @ConventionNo = 'X-20130118012',
                                             @dtDateTransfert = '2013-02-22',
                                             @mIQEE = 108.12,
                                             @mRendIQEE = 0,
                                             @mIQEE_Plus = 50,
                                             @mRendIQEE_Plus = 0

Paramètres de sortie:    

Historique des modifications:
    Date        Programmeur                 Description                                    Référence
    ----------  ------------------------    -----------------------------------------    ------------
    2013-02-27  Donald Huppé                Création du service        
    2015-09-03  Donald Huppé                Ajout de NLafond et MCadorette
    2016-01-06  Pierre-Luc Simard           Ajout de MEDurou
    2016-04-19  Maxime Martel               Ajout des montant de transfert IQEE et du numéro d'entreprise du québec (NEQ)
    2016-04-26  Patrice Côté                Enlèvement du NEQ en fin de compte
    2016-08-11  Donald Huppé			    Déterminer un connectID pour le userID et le passer à psTEMP_AjouterTransactionManuelleIQEEPourTIN
    2016-08-23  Maxime Martel	            Bloqué les transfert avec une date antérieur à celle du jour
	2016-09-30	Donald Huppé				jira TI-4920 : Donner le droit à cbourget
    2016-11-02	Pierre-Luc Simard			jira TI-5418 : Donner le droit à cheon
	2016-11-25	Donald Huppé				jira ti-5746 : Ajout de strichot
	2018-05-16	Donald Huppé				jira ti-12636 : ajout de anadeau
***********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psTEMP_LancerTraitementTIN_IQEE]
(
    @UserID varchar(255)
    ,@ConventionNo VARCHAR(15)
    ,@dtDateTransfert datetime
    ,@mIQEE    money
    ,@mRendIQEE money
    ,@mIQEE_Plus money
    ,@mRendIQEE_Plus money
    ,@mTotal_Transfert money
    ,@mCotisations_Donne_Droit_IQEE money
    ,@mCotisations_Non_Donne_Droit_IQEE money
    ,@mCotisations_Versees_Avant_Debut_IQEE money
)
AS
BEGIN

    declare
		@iConnectId INT,
        @ConventionID INT,
        @FaireTransfert int,
        @cMessage varchar(500),

        @TINNonTrouve1 bit/* = 0*/,
        @TINNonTrouve2 bit/* = 0*/,
        
        @mSolde_Credit_Base MONEY,
        @mSolde_Majoration MONEY,
        @mSolde_Interets_RQ MONEY,
        @mSolde_Interets_IQI MONEY,
        @mSolde_Interets_ICQ MONEY,
        @mSolde_Interets_IMQ MONEY,
        @mSolde_Interets_IIQ MONEY,
        @mSolde_Interets_III MONEY,
        @iCode_Retour int,
        @OtherTINdate VARCHAR(10),
        @iOperID INT,
        @bIsDebug bit = CASE @@Servername WHEN 'SRVSQL13' THEN 1 ELSE 0 END        

    DECLARE @tblResultatDebug            TABLE    
                                            (
                                            vNoConvention            VARCHAR(15)            
                                            ,vIdConvention            VARCHAR(15)
                                            ,vOperId                VARCHAR(10)
                                            ,vIdTransac                VARCHAR(10)
                                            ,vCBQ                    VARCHAR(10)
                                            ,vMMQ                    VARCHAR(10)
                                            ,vICQ                    VARCHAR(10)
                                            ,vIMQ                    VARCHAR(10)
                                            ,dtDateCreation            DateTime
                                            ,vTINExistant            varchar(3)
                                            ,vTINCree                varchar(3)
                                            )

    set @TINNonTrouve1 = 0
    set @TINNonTrouve2 = 0
    set @dtDateTransfert = Cast(@dtDateTransfert as DATE)
	        
    if not exists (select 1 from sysobjects where Name = 'tblTEMP_TINIQEE')
        begin
        create table tblTEMP_TINIQEE (conventionno varchar(20), DateInsert datetime) --drop table tblTEMP_TIOIQEE
        end

    set @cMessage = ''
    set @FaireTransfert = 1
    
    
    
    SELECT @ConventionID = ConventionID FROM dbo.Un_Convention WHERE ConventionNo = @ConventionNo
    
	 if @dtDateTransfert < Cast(GETDATE() as DATE)
        BEGIN
        set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Date du transfert antérieur à la date du jour'
        set @FaireTransfert = 0
        goto abort
        END

    -- vérifier que la convention existe
    if ISNULL(@ConventionID,0) = 0
        BEGIN
        set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Convention non trouvée.'
        set @FaireTransfert = 0
        goto abort
        END

    if     (@mIQEE + @mRendIQEE + @mIQEE_Plus + @mRendIQEE_Plus) = 0
        BEGIN
        set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Saisisez des montants de TIN.'
        set @FaireTransfert = 0
        
        END    

    -- faire même vérification que dans la sp psTEMP_AjouterTransactionManuelleIQEEPourTIN
    if not exists (
                SELECT TOP 1                    
                    O.OperId
                FROM         
                    Un_Cotisation C
                    INNER JOIN Un_Oper O ON C.OperID = O.OperID 
                    INNER JOIN dbo.Un_Unit U ON C.UnitID = U.UnitID 
                    INNER JOIN dbo.Un_Convention CO ON U.ConventionID = CO.ConventionID
                    INNER JOIN Un_TIN ON O.OperId = Un_TIN.OperId
                    INNER JOIN Un_ExternalPlan ON Un_ExternalPlan.ExternalPlanID = Un_TIN.ExternalPlanID
                    INNER JOIN Un_ExternalPromo ON Un_ExternalPromo.ExternalPromoID = Un_ExternalPlan.ExternalPromoID
                    INNER JOIN Mo_Company ON Mo_Company.CompanyID = Un_ExternalPromo.ExternalPromoID
                WHERE
                    CO.ConventionNo = @ConventionNo 
                    AND
                    O.OperTypeID = 'TIN'
                    AND
                    Un_TIN.ExternalPlanID NOT IN (86,87,88) -- Id correspondant au promoteur Universitas
                ORDER BY
                    O.OperDate DESC
        )
        BEGIN
        set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Aucun TIN externe trouvé.  Traitement impossible.'
        set @TINNonTrouve2 = 1
        set @FaireTransfert = 0
        goto abort
        END

    IF exists (
        SELECT 1
        FROM dbo.Un_Convention c
        join Un_ConventionOper co on c.ConventionID = co.ConventionID
        join un_oper o on co.OperID = o.OperID
        where 
            c.ConventionNo = @ConventionNo
            AND    O.OperDate = @dtDateTransfert
            AND    O.OperTypeID = 'TIN'
            and co.ConventionOperTypeID IN ('CBQ','MMQ','IQI')
            )
        BEGIN
        set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Montant(s) d''IQEE déjà présent(s) dans un TIN à cette date. Traitement annulé.'
        set @FaireTransfert = 0
        goto abort
        END    

    SELECT top 1 @iOperID = O.OperId
    FROM         
        Un_Cotisation C
        INNER JOIN Un_Oper O ON C.OperID = O.OperID 
        INNER JOIN dbo.Un_Unit U ON C.UnitID = U.UnitID 
        INNER JOIN dbo.Un_Convention CO ON U.ConventionID = CO.ConventionID
    WHERE
        CO.ConventionNo = @ConventionNo 
        AND
        O.OperDate = @dtDateTransfert
        AND
        O.OperTypeID = 'TIN'

    -- faire même vérification que dans la sp psTEMP_AjouterTransactionManuelleIQEEPourTIN
    if @iOperID IS NULL
        BEGIN
        set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'PAS de TIN trouvé le : ' + LEFT(CONVERT(VARCHAR, @dtDateTransfert, 120), 10)  + '.'
        set @TINNonTrouve1 = 1
        set @FaireTransfert = 0
        
        END
        
    if @TINNonTrouve1 = 1 and exists (
        SELECT TOP 1 O.OPERID
            --LEFT(CONVERT(VARCHAR, max(O.operdate), 120), 10)-- On informe l'usager
        
        FROM         
            Un_Cotisation C
            JOIN Un_Oper O ON C.OperID = O.OperID 
            JOIN Un_TIN ON O.OperId = Un_TIN.OperId
            JOIN dbo.Un_Unit U ON C.UnitID = U.UnitID 
            JOIN dbo.Un_Convention CO ON U.ConventionID = CO.ConventionID
        WHERE
            CO.ConventionNo = @ConventionNo 
            AND O.OperTypeID = 'TIN'
            AND    Un_TIN.ExternalPlanID NOT IN (86,87,88)    
                    )    
        BEGIN
            SELECT @OtherTINdate = LEFT(CONVERT(VARCHAR, max(O.operdate), 120), 10) -- On informe l'usager
                , @iOperID = MAX(O.OperID)
            FROM         
                Un_Cotisation C
                JOIN Un_Oper O ON C.OperID = O.OperID 
                JOIN Un_TIN ON O.OperId = Un_TIN.OperId
                JOIN dbo.Un_Unit U ON C.UnitID = U.UnitID 
                JOIN dbo.Un_Convention CO ON U.ConventionID = CO.ConventionID
            WHERE
                CO.ConventionNo = @ConventionNo 
                AND O.OperTypeID = 'TIN'
                AND    Un_TIN.ExternalPlanID NOT IN (86,87,88)    
        
            SET @TINNonTrouve1 = 0 -- on présume donc qu'on a trouvé un TIN.
            SET @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'MAIS TIN trouvé le : ' + @OtherTINdate  + '.' + char(10) + ' Création d''un TIN, basé sur ce dernier.' 
            set @FaireTransfert = 1
        END
        -- on regarde s'il n'y en a pas un à une autre date.  donc on n'aurait pas saisi la bonne date

    -- vérification que l'usager à le droit
    if (@UserID					not like '%dhuppe%' 
					and @UserID not like '%fmenard%' 
					and @UserID not like '%MGobeil%' 
					and @UserID not like '%menicolas%' 
					and @UserID not like '%mcadorette%' 
					and @UserID not like '%nlafond%' 
					and @UserID not like '%medurou%'
					and @UserID not like '%cbourget%'
                    and @UserID not like '%cheon%'
					and @UserID not like '%strichot%'
					and @UserID not like '%anadeau%'
					)
                and @@SERVERNAME <> 'SRVSQL13'
        begin
        set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Usager non autorisé : ' + @UserID
        set @FaireTransfert = 0
        goto abort
        end

	SELECT @iConnectId = isnull(MAX(CO.ConnectID),2)
	FROM Mo_Connect CO
	JOIN mo_user u on co.UserID = u.UserID
	WHERE CharIndex(u.LoginNameID, @UserID, 1) > 0

    if @FaireTransfert = 1
    
        begin
        
        -- inserer la demande dans tblTEMP_TransacManuelleIQEE
        INSERT INTO tblTEMP_TransacManuelleIQEE([vConventionNo] ,[dtDateTransfert],[dtDateCheque],[mIQEE] ,[mRendIQEE],[mIQEE_Plus],[mRendIQEE_Plus],
                    [cTraiter],[vcTypeTransfert], [mTotal_Transfert], [mCotisations_AyantDroit_IQEE], [mCotisations_NonDroit_IQEE],[mCotisations_Avant_IQEE]) 
        VALUES(@ConventionNo,@dtDateTransfert,NULL,@mIQEE,@mRendIQEE,@mIQEE_Plus,@mRendIQEE_Plus,'N','TIN', 
                @mTotal_Transfert, @mCotisations_Donne_Droit_IQEE, @mCotisations_Non_Donne_Droit_IQEE, @mCotisations_Versees_Avant_Debut_IQEE)
                
                
        /*****************DEBUG**********************/
        --If @bIsDebug <> 0
        --    SELECT * FROM tblTEMP_TransacManuelleIQEE WHERE IidTransacManuelleIQEE = SCOPE_IDENTITY() 
        /********************************************/        
        
        -- Faire la job.  comme les validation sont déjà faites, ça devrait passer comme du beures dans la poêle (ou comme papa dans maman)
        insert into @tblResultatDebug
		EXEC @iCode_Retour = [psTEMP_AjouterTransactionManuelleIQEEPourTIN]  --@ConventionNo, 2, @iConnectId
								@vConventionNo = @ConventionNo
								,@bActiveDebug =2
								,@ConnectId	= @iConnectId	
    
        -- vérifier que la job a pas planté
        if @iCode_Retour <> 0
            begin
                set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Erreur de traitement. Communiquer les TI. '
            end    
        end    
    
    -- si la job a rien fait, je supprime l'entrée dans tblTEMP_TransacManuelleIQEE.  elle sera créé à nouveau s'il y a une nouvelle demande
    if exists (select 1 from @tblResultatDebug where vNoConvention = @ConventionNo and vTINExistant = 'NON' and vTINCree = 'NON')
        begin
        delete from tblTEMP_TransacManuelleIQEE where vConventionNo = @ConventionNo and dtDateTransfert = @dtDateTransfert and cTraiter = 'N' and vcTypeTransfert = 'TIN'
        set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Traitement NON effectué. Aucun TIN trouvé.'
        end

    -- si un TIN a été créé, je suprpimer toute demande nono traité de cette convention au cas où il y en a, mais ça devrait pas.
    if exists (select 1 from @tblResultatDebug where vNoConvention = @ConventionNo and vTINExistant = 'NON' and vTINCree = 'OUI')
        begin
        delete from tblTEMP_TransacManuelleIQEE where vConventionNo = @ConventionNo and dtDateTransfert = @dtDateTransfert and cTraiter = 'N' and vcTypeTransfert = 'TIN'
        set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Nouveau TIN créé avec succès.'
        end

    -- si un TIN était existant en date demandée, je suprpime toute demande non traité de cette convention au cas où il y en a, mais ça devrait pas.
    if exists (select 1 from @tblResultatDebug where vNoConvention = @ConventionNo and vTINExistant = 'OUI' and vTINCree = 'NON')
        begin
        delete from tblTEMP_TransacManuelleIQEE where vConventionNo = @ConventionNo and dtDateTransfert = @dtDateTransfert and cTraiter = 'N' and vcTypeTransfert = 'TIN'
        set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'TIN existant complété.'
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
        ,vTINExistant = isnull(vTINExistant,'')
        ,vTINCree = isnull(vTINCree ,'')
        ,vOperId = isnull(vOperId ,0)
        ,vCBQ = isnull(vCBQ ,0)
        ,vMMQ = isnull(vMMQ ,0)
        ,vICQ = isnull(vICQ ,0)
        ,vIMQ = isnull(vIMQ ,0)
    from 
        #tMessage m
    left join @tblResultatDebug r on 1=1
END
