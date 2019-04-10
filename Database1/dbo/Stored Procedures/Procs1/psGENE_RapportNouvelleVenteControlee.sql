
/****************************************************************************************************
Code de service		:		psGENE_RapportNouvelleVenteControlee
Nom du service		:		Ce service est utilisé pour générer un rapport sur les nouvelles ventes controlé avec la loupe
But					:		
Facette				:		GENE 
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------

Exemple d'appel:

EXEC psGENE_RapportNouvelleVenteControlee
								@DateDu = '2015-02-02',
								@DateAu = '2015-02-08'

EXEC psGENE_RapportNouvelleVenteControlee
								@DateDu = null,
								@DateAu = null

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
                       tblGENE_TypeNote	            Tous

Historique des modifications :			
						Date						Programmeur								Description							Référence
						2015-02-09					Donald Huppé							Création du service
 ****************************************************************************************************/

CREATE PROCEDURE dbo.psGENE_RapportNouvelleVenteControlee
							(	
								@DateDu	DATETIME,
								@DateAu	DATETIME
                             )
AS
	BEGIN

	--if @DateDu = null set @DateDu = '2015-02-02'
	--if @DateAu = null set @DateAu = '2015-02-08'

set arithabort on

	SELECT DISTINCT 
		Agent = hu.FirstName + ' ' + hu.LastName
		,Souscripteur = hs.FirstName + ' ' + hs.LastName
		,IDsouscripteur = c.SubscriberID
		,c.ConventionNo
		,DateSignature = LEFT(CONVERT(VARCHAR, un.SignatureDate, 120), 10)
		,Représentant = hr.FirstName + ' ' + hr.LastName
		,Directeur = hb.FirstName + ' ' + hb.LastName

	FROM dbo.Un_Convention c
	JOIN dbo.Mo_Human hs on c.SubscriberID = hs.HumanID
	JOIN dbo.Un_Unit un on c.ConventionID = un.ConventionID
	JOIN dbo.Mo_Human hr on un.RepID = hr.HumanID
	JOIN Mo_Connect cn ON un.ActivationConnectID = cn.ConnectID
	join Mo_User u ON cn.UserID = u.UserID
	JOIN dbo.Mo_Human hu on cn.UserID = hu.HumanID
	join (
		SELECT 
			M.UnitID,
			BossID = MAX(RBH.BossID)
		FROM (
			SELECT 
				U.UnitID,
				U.RepID,
				RepBossPct = MAX(RBH.RepBossPct)
			FROM dbo.Un_Unit U
			JOIN Un_RepBossHist RBH ON RBH.RepID = U.RepID AND (U.InForceDate >= RBH.StartDate) AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND (RBH.RepRoleID = 'DIR')
			JOIN Un_RepLevel BRL ON (BRL.RepRoleID = RBH.RepRoleID)
			JOIN Un_RepLevelHist BRLH ON (BRLH.RepLevelID = BRL.RepLevelID) AND (BRLH.RepID = RBH.BossID) AND (U.InForceDate >= BRLH.StartDate)  AND (U.InForceDate <= BRLH.EndDate  OR BRLH.EndDate IS NULL)
			GROUP BY U.UnitID, U.RepID
			) M
		JOIN dbo.Un_Unit U ON U.UnitID = M.UnitID
		JOIN Un_RepBossHist RBH ON RBH.RepID = M.RepID AND RBH.RepBossPct = M.RepBossPct AND (U.InForceDate >= RBH.StartDate)  AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND RBH.RepRoleID = 'DIR'
		GROUP BY 
			M.UnitID
		) bu on un.UnitID = bu.UnitID
	JOIN dbo.Mo_Human hb on bu.BossID = hb.HumanID
	WHERE LEFT(CONVERT(VARCHAR, cn.ConnectStart, 120), 10) BETWEEN @DateDu and @DateAu

	ORDER by 
		hu.FirstName + ' ' + hu.LastName,
		c.ConventionNo

set arithabort OFF

end


