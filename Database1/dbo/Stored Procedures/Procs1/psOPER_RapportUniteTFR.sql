/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service : psOPER_RapportUniteTFR
Nom du service  : Rapport des unités TFR. 
But             : Ce sont les unités utilisées dans les frais disponibles. (jira ti-11936)
Facette         : OPER

Paramètres d’entrée :
Paramètre                  Description
-------------------------- --------------------------------------------------------------------------


Paramètres de sortie: 
Paramètre                 Champ(s)                                              Description
------------------------- ----------------------------------------------------- ---------------------------


Exemple d’appel     : EXECUTE dbo.psOPER_RapportUniteTFR '2018-04-01','2018-04-24'

Historique des modifications:
        Date            Programmeur                         Description
        ------------    ---------------------------------- ---------------------------
        2018-04-24      Donald Huppé                       Création du service

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_RapportUniteTFR]
(
   @dtStartDate   DATETIME
  ,@dtEndDate   DATETIME
)
AS
BEGIN


		SELECT 
			cv.ConventionNo,
			cv.SubscriberID,
			U1.UnitID,
			Date1erDepot = cast(U1.dtFirstDeposit as date),
			NbUniteSouscrite = u1.UnitQty + isnull(rr1.QteRES_u1,0),
			--TransferDeFraisAppliquéUnité = A.fUnitQtyUse,
			TransferDeFraisAppliquéFrais = c.Fee,
			DateTFR = CAST ( o.OperDate as date),
			RepUtilisationFrais = hr1.FirstName + ' ' + hr1.LastName,			
				
			ConventionOriginale = CvOri.ConventionNo,
			UnitID_Ori = Uori.unitid,
			Date1erDepotOriginal = cast(Uori.dtFirstDeposit as date),
			NombreUniteSouscriteOriginale = Uori.UnitQty + isnull(rr.QteRES,0),
			RepOriginal = hrOri.FirstName + ' ' + hrOri.LastName


			
		FROM 
			Un_AvailableFeeUse A
			JOIN Un_Oper O ON O.OperID = A.OperID
			JOIN Un_Cotisation C ON C.OperID = O.OperID
			JOIN dbo.Un_Unit U1 ON U1.UnitID = C.UnitID
			JOIN Mo_Human hr1 on hr1.HumanID = u1.RepID
			JOIN dbo.Un_Convention Cv on U1.conventionid = Cv.conventionid

			JOIN Un_UnitReduction UR on a.unitreductionid = UR.unitreductionid 
			JOIN dbo.Un_Unit Uori on UR.unitid = Uori.unitid
			JOIN Mo_Human hrOri on hrOri.HumanID = Uori.RepID
			JOIN dbo.Un_Convention CvOri on Uori.conventionid = CvOri.conventionid 
		
			LEFT JOIN (select UnitID, QteRES_u1 = sum(UnitQty) from Un_UnitReduction group by UnitID) rr1 on U1.UnitID = rr1.UnitID
			LEFT JOIN (select UnitID, QteRES = sum(UnitQty) from Un_UnitReduction group by UnitID) rr on Uori.UnitID = rr.UnitID

			LEFT JOIN Un_OperCancelation oc1 on oc1.OperSourceID = o.OperID
			LEFT JOIN Un_OperCancelation oc2 on oc2.OperID = o.OperID

		WHERE 1=1
			AND o.OperDate BETWEEN @dtStartDate and @dtEndDate
			AND oc1.OperSourceID is NULL
			AND oc2.OperID is NULL
			AND o.OperTypeID = 'TFR'
			AND c.Fee > 0
			

		ORDER BY o.OperDate DESC

END