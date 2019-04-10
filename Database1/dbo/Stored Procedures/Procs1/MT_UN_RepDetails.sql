
/****************************************************************************************************
Code de service		:		MT_UN_RepDetails
Nom du service		:		
But					:		
Description			:		

Facette				:		
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						MatrixID					Identifiant du représentant

Exemple d'appel:
					EXECUTE dbo.MT_UN_RepDetails NULL
		
Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
						Un_Rep						RepID 
													RepCode 
													RepLicenseNo
													BusinessStart
													BusinessEnd
													HistVerifConnectID
													iNumeroBDNI
						
						Mo_Human					FirstName													
													OrigName
													Initial													
													LastName
													CompanyName
													SexID
													AdrID
													BirthDate
													DeathDate
													LangID
													CivilID
													CourtesyTitle
													UsingSocialNumber
													SharePersonalInfo
													MarketingMaterial
													IsCompany
													SocialNumber
													DriverLicenseNo
													WebSite
													ResidID
													BossID
													
						Mo_Adr
													InForce
													AdrTypeID
													SourceID
													Address
													City
													StateName
													CountryID
													ZipCode
													Phone1
													Phone2
													Fax
													Mobile
													WattLine
													OtherTel
													Pager
													EMail
													
Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-11-23					Jean-François Gauthier					Création de la procédure
						2010-02-22					Jean-François Gauthier					Ajout du champ iNumeroBDNI en retour
						2010-003-05					Jean-François Gauthier					Ajout du champ vcPrenom
                        2017-12-05                  Pierre-Luc Simard                       Ne plus valider la table Un_RepBusinessBonusCfg
						
N.B.
Le code de la procédure ne respecte pas les conventions de programmation, car elle doit remplacer
des éléments existants dans UniAcces et elle a été conçue à partir du code SQL existant.
						
 ****************************************************************************************************/

CREATE PROCEDURE [dbo].[MT_UN_RepDetails] 
		(
			@MatrixID INT
		)

AS
	BEGIN
		SET NOCOUNT ON

		DECLARE @dtDateDuJour DATETIME

 		SET @dtDateDuJour = GETDATE()

		SELECT
			R.RepID, R.RepCode, R.RepLicenseNo,
			R.BusinessStart, R.BusinessEnd,
			HistVerifConnectID = ISNULL(R.HistVerifConnectID, 0),
			RFirstname = RH.FirstName	+ CASE
												WHEN R.RepCode IS NULL THEN ''
												ELSE ' (' + R.RepCode + ')'
											END
										+ CASE
												WHEN R.BusinessEnd IS NULL THEN ''
												ELSE ' (Inactif)'
											END,
			ROrigName = RH.OrigName,
			RInitial = RH.Initial,
			RLastName = RH.LastName,
			RCompanyName = RH.CompanyName,
			RSexID = RH.SexID,
			RAdrID = RH.AdrID,
			RBirthDate = RH.BirthDate,
			RDeathDate = RH.DeathDate,
			RLangID = RH.LangID,
			RCivilID = RH.CivilID,
			RCourtesyTitle = RH.CourtesyTitle,
			RUsingSocialNumber = RH.UsingSocialNumber,
			RSharePersonalInfo = RH.SharePersonalInfo,
			RMarketingMaterial = RH.MarketingMaterial,
			RIsCompany = RH.IsCompany,
			RSocialNumber = RH.SocialNumber,
			RDriverLicenseNo = RH.DriverLicenseNo,
			RWebSite = RH.WebSite,
			RResidID = RH.ResidID,
			RInForce = RA.InForce,
			RAdrTypeID = RA.AdrTypeID,
			RSourceID = RA.SourceID,
			RAddress = RA.Address,
			RCity = RA.City,
			RStateName = RA.StateName,
			RCountryID = RA.CountryID,
			RZipCode = RA.ZipCode,
			RPhone1		= dbo.FN_CRQ_FormatPhoneNo(RA.Phone1, RA.CountryID),
			RPhone2		= dbo.FN_CRQ_FormatPhoneNo(RA.Phone2, RA.CountryID),
			RFax		= dbo.FN_CRQ_FormatPhoneNo(RA.Fax, RA.CountryID),
			RMobile		= dbo.FN_CRQ_FormatPhoneNo(RA.Mobile, RA.CountryID),
			RWattLine	= dbo.FN_CRQ_FormatPhoneNo(RA.WattLine, RA.CountryID),
			ROtherTel	= dbo.FN_CRQ_FormatPhoneNo(RA.OtherTel, RA.CountryID),
			RPager		= dbo.FN_CRQ_FormatPhoneNo(RA.Pager, RA.CountryID),
			REMail = RA.EMail,
			RDirName =	CASE ISNULL(RDIR.BossID,0)
							WHEN 0 THEN ''
							ELSE HRDIR.LastName +  ', ' +  HRDIR.FirstName
						END,
			R.iNumeroBDNI,
			vcPrenom = RH.FirstName
		FROM
			Un_Rep R
			LEFT JOIN Un_Rep RH_Rep
				ON RH_Rep.RepID = R.RepID
			LEFT JOIN dbo.Mo_Human RH
				ON RH.HumanID = RH_Rep.RepID
			LEFT JOIN dbo.Mo_Adr RA
				ON RA.AdrID = RH.AdrID
			LEFT JOIN (
						SELECT
							M.RepID,
							BossID = MAX(RBH.BossID)
						FROM (
								SELECT
									R.RepID,
									RepBossPct = MAX(RBH.RepBossPct)
								FROM
									Un_Rep R
									JOIN Un_RepBossHist RBH
										ON RBH.RepID = R.RepID AND (@dtDateDuJour >= RBH.StartDate) AND (@dtDateDuJour <= RBH.EndDate OR RBH.EndDate IS NULL) AND RBH.RepRoleID = 'DIR'
									JOIN Un_RepLevel BRL
										ON BRL.RepRoleID = RBH.RepRoleID
									JOIN Un_RepLevelHist BRLH
										ON BRLH.RepLevelID = BRL.RepLevelID AND BRLH.RepID = RBH.BossID AND (@dtDateDuJour >= BRLH.StartDate) AND (@dtDateDuJour <= BRLH.EndDate OR BRLH.EndDate IS NULL)
									--JOIN Un_RepBusinessBonusCfg RBB
										--ON RBB.RepRoleID = RBH.RepRoleID AND (@dtDateDuJour >= RBB.StartDate) AND (@dtDateDuJour <= RBB.EndDate OR RBB.EndDate IS NULL)
								WHERE
									R.RepID = @MatrixID
								GROUP BY R.RepID
						) M
							JOIN Un_Rep R
								ON R.RepID = M.RepID
							JOIN Un_RepBossHist RBH
								ON RBH.RepID = M.RepID AND RBH.RepBossPct = M.RepBossPct AND (@dtDateDuJour >= RBH.StartDate) AND (@dtDateDuJour <= RBH.EndDate OR RBH.EndDate IS NULL) AND RBH.RepRoleID = 'DIR'
						WHERE
							R.RepID = @MatrixID
						GROUP BY M.RepID
						) RDIR ON RDIR.RepID = R.RepID
			LEFT JOIN dbo.Mo_Human HRDIR
				ON HRDIR.HumanID = RDIR.BossID
		WHERE
			R.RepID =  @MatrixID
		ORDER BY
			RH.LastName,
			RH.FirstName
	END


