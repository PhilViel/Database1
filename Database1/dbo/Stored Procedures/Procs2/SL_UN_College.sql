/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_College
Description         :	Liste des collèges
Valeurs de retours  :	Dataset :
Note                :						2004-06-07	Bruno Lapointe		Création
													2004-08-18	Bruno Lapointe		Modification du ISNULL du website pour qu'il 
																							retourne une ligne vide plutôt que 0.
								ADX0000730	IA	2005-06-13	Bruno Lapointe		Renommé
								ADX0000730	IA	2005-06-16	Bernie MacIntyre	EligibilityConditionID rajouté
								ADX0000730	IA	2005-07-07	Bruno Lapointe		Retourner iSectorID, vcSector, iRegionID et vcRegion
								ADX0001657	BR	2005-10-25	Bruno Lapointe		Ajouter un lien sur les départements de type inconnu
																							(DepTypeID = 'U').  De cette façon on récupère tout
																							le temps l'adresse.
								ADX0001743	BR	2005-11-14	Bruno Lapointe		Enlever le lien sur les départements de type inconnu
																							(DepTypeID = 'U').  Cela causait d'autres problèmes.
																							Mettre 'A' par défaut pour les DepTypeID qui snt NULL.
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_College] (
	@CollegeID INTEGER -- 0 tous ou ID Unique de celui désiré
)
AS
BEGIN
	SELECT  
		C.CollegeID,
		CollegeName = ISNULL(Co.CompanyName,'Unknow'),
		C.EligibilityConditionID,
		C.CollegeCode,
		C.CollegeTypeID,
		C.iSectorID,
		S.vcSector,
		C.iRegionID,
		R.vcRegion,
		LangID = ISNULL(Co.LangID,'U'),
		WebSite = ISNULL(Co.WebSite,''),
		StateTaxNumber = ISNULL(Co.StateTaxNumber,''),
		CountryTaxNumber = ISNULL(Co.CountryTaxNumber,''),
		EndBusiness = dbo.FN_CRQ_IsDateNull (Co.EndBusiness),
		DepType = ISNULL(D.DepType,'A'),
		Att = ISNULL(D.Att,''),
		AdrID = ISNULL(D.AdrID,0),
		InForce = dbo.FN_CRQ_IsDateNull (A.InForce),
		AdrTypeID = ISNULL(A.AdrTypeID,'C'),
		Address = ISNULL(A.Address,''),
		City = ISNULL(A.City,''),
		StateName = ISNULL(A.StateName,''),
		CountryID = ISNULL(A.CountryID,'UNK'),
		ZipCode = ISNULL(A.ZipCode,''),
		Phone1 = ISNULL(A.Phone1,''),
		Phone2 = ISNULL(A.Phone2,''),
		Fax = ISNULL(A.Fax,''),
		Mobile = ISNULL(A.Mobile,''),
		WattLine = ISNULL(A.WattLine,''),
		OtherTel = ISNULL(A.OtherTel,''),
		Pager = ISNULL(A.Pager,''),
		EMail = ISNULL(A.EMail,'')
	FROM Un_College C
	LEFT JOIN Mo_Company Co ON Co.CompanyID = C.CollegeID
	LEFT JOIN Mo_Dep D ON D.CompanyID = Co.CompanyID AND D.DepType = 'A'
	LEFT JOIN dbo.Mo_Adr A ON A.AdrID = D.AdrID
	LEFT JOIN Un_Sector S ON S.iSectorID = C.iSectorID
	LEFT JOIN Un_Region R ON R.iRegionID = C.iRegionID
	WHERE @CollegeID = 0
		OR @CollegeID = C.CollegeID
	ORDER BY 
		Co.CompanyName, 
		C.CollegeCode, 
		C.CollegeTypeID
END


