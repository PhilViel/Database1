/****************************************************************************************************
Copyrights (c) 2011 Gestion Universitas inc.

Code du service		: psCONV_RapportLettre_le_ch_ep_TRI
Nom du service		: Générer la lettre le_ch_ep_TRI
But 				: 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	EXECUTE psCONV_RapportLettre_le_ch_ep_TRI 'I-20121012019'
						EXECUTE psCONV_RapportLettre_le_ch_ep_TRI 'I-20120509001'

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2013-09-27		Donald Huppé et Maxime Martel		Création du service		
		2014-06-19		Maxime Martel						Remplacer mo_adr par la fonction pour obtenir l'adresse
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportLettre_le_ch_ep_TRI] 
(
	@cConventionno varchar(15)  --Filtre sur un numéro de convention
)
AS
BEGIN

	declare @today datetime, @humanID integer
	
	set @today = GETDATE()
	SET @cConventionno = UPPER(LTRIM(RTRIM(ISNULL(@cConventionno,''))))

	select @humanID = C.subscriberID FROM dbo.Un_Convention C where C.ConventionNo = @cConventionno

	SELECT 
		
		c.ConventionNo, 
		ConvCollective = ltrim(rtrim(STUFF(( SELECT distinct ' et ' + cs.ConventionNo   AS [text()]
							FROM dbo.Un_Convention cd
							join tblOPER_OperationsRIO r ON cd.ConventionID = r.iID_Convention_Destination and r.bRIO_Annulee = 0 and r.bRIO_QuiAnnule = 0 and r.OperTypeID = 'TRI'
							JOIN dbo.Un_Convention cs on r.iID_Convention_Source = cs.ConventionID
							where cd.ConventionNo = @cConventionno 
								FOR XML PATH('')
								), 1, 3, '' ))),
		NbConvCollective = 	(
							SELECT COUNT(DISTINCT cs.ConventionNo)
							FROM dbo.Un_Convention cd
							join tblOPER_OperationsRIO r ON cd.ConventionID = r.iID_Convention_Destination and r.bRIO_Annulee = 0 and r.bRIO_QuiAnnule = 0 and r.OperTypeID = 'TRI'
							JOIN dbo.Un_Convention cs on r.iID_Convention_Source = cs.ConventionID
							where cd.ConventionNo = @cConventionno
						)	,				
		CaptialDepose = isnull(ctTRI.CaptialDepose,0), 
		FraisEncouru = isnull(ctTRI.FraisEncouru,0) ,
		Remboursement = isnull(ctRET.Remboursement,0),
		Bec = ISNULL(bec.BEC,0),
		sex.LongSexName as appelLong,
		sex.ShortSexName as appelCourt,
		HS.HumanID as idSouscripteur,
		hs.LastName as nomSouscripteur,
		hs.firstName as prenomSouscripteur,
		LangID = hs.LangID,
		hb.firstName as prenomBene,
		hb.SexID,
		a.vcNom_Rue as Address,
		a.vcVille as City,
		ZipCode = dbo.fn_Mo_FormatZIP( a.vcCodePostal,A.cId_Pays),
		a.vcProvince as StateName,
		PlanClassification = [dbo].[fnCONV_ObtenirDossierClient](c.subscriberID,1) + '\' + 
			replace(LEFT(CONVERT(VARCHAR, @today, 120), 10),'-','') + 
			case hs.langID when 'FRA' then '_le_ch_ep_TRI' when 'ENU' then '_le_ch_ep_TRI_ang' end
	from
		Un_Convention c
		JOIN dbo.Un_Subscriber S on C.subscriberID = S.SubscriberID 
		JOIN dbo.Mo_Human HS on S.SubscriberID = HS.HumanID
		join Mo_Sex sex ON sex.SexID = hs.SexID AND sex.LangID = hs.LangID
		JOIN dbo.mo_Human HB on C.BeneficiaryID = HB.humanID
		join dbo.fntGENE_ObtenirAdresseEnDate(@humanID,1,GETDATE(),1) A on A.iID_Source = HS.HumanID
		join( 
			select DISTINCT cr.ConventionID--, ConventionIDCol = cCol.ConventionID
			from tblOPER_OperationsRIO r1 
			JOIN dbo.Un_Convention cr ON cr.ConventionID = r1.iID_Convention_Destination AND r1.bRIO_Annulee = 0 AND r1.bRIO_QuiAnnule = 0 AND r1.OperTypeID = 'TRI'
			--JOIN dbo.Un_Convention cCol	ON r1.iID_Convention_Source = cCol.ConventionID
			where cr.ConventionNo = @cConventionno
		) cRio on cRio.ConventionID = c.ConventionID
		--left JOIN dbo.Un_Convention cCol on crio.ConventionIDCol = cCol.ConventionID
		left JOIN (
			SELECT c.ConventionID, CaptialDepose = abs(sum(ct.Cotisation + ct.Fee)), FraisEncouru = SUM(ct.Fee)
			FROM dbo.Un_Unit u
			JOIN dbo.Un_Convention c ON u.ConventionID = c.ConventionID
			join Un_Cotisation ct on u.UnitID = ct.UnitID	
			join un_oper o ON ct.OperID = o.OperID
			WHERE o.OperTypeID = 'TRI'
			and c.ConventionNo = @cConventionno
			GROUP by c.ConventionID
			)ctTRI ON c.Conventionid = ctTRI.ConventionID
		left JOIN (
			SELECT c.ConventionID, Remboursement = abs(sum(ct.Cotisation + ct.Fee))
			FROM dbo.Un_Unit u
			JOIN dbo.Un_Convention c ON u.ConventionID = c.ConventionID
			join Un_Cotisation ct on u.UnitID = ct.UnitID	
			join un_oper o ON ct.OperID = o.OperID
			WHERE o.OperTypeID = 'RET'
			and c.ConventionNo = @cConventionno
			GROUP by c.ConventionID
			)ctRET ON c.Conventionid = ctRET.ConventionId
		LEFT JOIN (
            SELECT ce.ConventionID, BEC = SUM(ce.fCLB)
            from Un_CESP ce
            JOIN dbo.Un_Convention c on ce.ConventionID = c.ConventionID
            where c.ConventionNo = @cConventionno
            group by ce.ConventionID
            ) BEC on c.ConventionID = BEC.ConventionID

	WHERE c.ConventionNo = @cConventionno
end


