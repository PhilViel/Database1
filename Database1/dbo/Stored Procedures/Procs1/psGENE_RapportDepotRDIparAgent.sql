
/****************************************************************************************************
Code de service		:		psGENE_RapportDepotRDIparAgent
Nom du service		:		psGENE_RapportDepotRDIparAgent
But					:		JIRA PROD-9513 : Pour connaitre le nb de RDI traités par agent dans une période
Facette				:		GENE
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						@dtStartDate				Début de la période
						@dtEndDate					Fin de la période

Exemple d'appel:
						 exec psGENE_RapportDepotRDIparAgent '2018-01-01', '2018-04-30'


Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					-----------------------------


Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2018-05-09					Donald Huppé							Création du Service
						
 ****************************************************************************************************/

CREATE PROCEDURE [dbo].[psGENE_RapportDepotRDIparAgent] (
	@dtStartDate DATETIME,
	@dtEndDate DATETIME
	)


AS
BEGIN

	SET ARITHABORT ON

	SELECT
		DISTINCT
		c.ConventionNo,
		c.SubscriberID,
		NomSoucripteur = hs.FirstName + ' '+ hs.LastName,
		U.UnitID,
		ct.CotisationID,
		NbTrans = 1,
		ModeDepot = CASE 
			WHEN m.PmtQty = 1 THEN 'Forfaitaire'
			WHEN m.PmtByYearID = 12 THEN 'Mensuel'
			WHEN m.PmtByYearID = 1 AND m.PmtQty > 1 THEN 'Annuel'
			END
		,DateDeTraitement = o.dtSequence_Operation
		,DateEffective = CAST(ct.EffectDate AS DATE)
		,MontantRDI = ct.Cotisation + ct.Fee + ct.BenefInsur + ct.SubscInsur + ct.TaxOnInsur
		,Agent = h.FirstName + ' ' + h.LastName
	FROM Un_Convention c
		JOIN Mo_Human hs on hs.HumanID = c.SubscriberID
		JOIN Un_Unit u on c.ConventionID = u.ConventionID
		JOIN Un_Modal m on u.ModalID = m.ModalID
		JOIN Un_Cotisation ct on u.UnitID = ct.UnitID
		JOIN un_oper o on ct.OperID = o.OperID
		JOIN Mo_Connect cn on cn.ConnectID = o.ConnectID
		JOIN mo_user us on us.UserID = cn.UserID
		JOIN Mo_Human h on h.HumanID = us.UserID
	WHERE 
		o.OperTypeID = 'RDI'
		AND o.dtSequence_Operation BETWEEN @dtStartDate AND @dtEndDate

	SET ARITHABORT OFF

END