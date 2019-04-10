/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service : psOPER_RDI_RechercherPaiements
Nom du service  : Rechercher les paiements.
But             : Rechercher les paiements selon les critères de sélection de l'utilisateur.
Facette         : OPER

Paramètres d’entrée :
Paramètre                  Description
-------------------------- --------------------------------------------------------------------------
@cID_Langue                Identifiant unique de la langue de l’utilisateur selon « Mo_Lang ».
                           Le français est la langue par défaut si elle n’est pas spécifiée.
@dtDate_Depot_Debut        Date de début du dépôt.  Si elle est vide, toutes les dates de dépôts
                           sont considérées ou jusqu’à la date de fin si elle est non vide.
@dtDate_Depot_Fin          Date de fin du dépôt.  Si elle est vide, toutes les dates de dépôts
                           sont considérées ou à partir de la date de début si elle est non vide.
@vcNom_Deposant            Nom du déposant.  S'il est vide, tous les déposants sont considérés.
@vcNo_Document             Numéro de document entré par le déposant.  S'il est vide, tous les numéros sont considérés.
@tiNonAssigné              Provient de la valeur de la case à cocher de l'interface.
                           1 = coché
                           0 = non coché

Paramètres de sortie:
Paramètre                 Champ(s)                                           Description
------------------------- ----------------------------------------           ---------------------------
iID_RDI_Depot             fntOPER_RDI_RechercherPaiements.iID_RDI_Depot      Identifiant unique du dépôt associé au paiement
iID_RDI_Paiement          fntOPER_RDI_RechercherPaiements.iID_RDI_Paiement   Identifiant unique d'un paiement
dtDate_Depot              tblOPER_RDI_Depots.dtDate_Depot                    Date du dépot associé au paiement
vcNom_Deposant            fntOPER_RDI_RechercherPaiements.vcNom_Deposant     Nom du déposant
vcNo_Document             fntOPER_RDI_RechercherPaiements.vcNo_Document      Numéro de document entré par le déposant
vcSouscripteur            fntOPER_RDI_RechercherPaiements.vcSouscripteur     Nom du souscripteur existant dans UniAccès
vcNo_Oper                 fntOPER_RDI_RechercherPaiements.vcNo_Oper          Numéro de l'opération du paiement
mMontant_Paiement         fntOPER_RDI_RechercherPaiements.mMontant_Paiement  Montant du paiement
mMontant_Assigne          fntOPER_RDI_RechercherPaiements.mMontant_Assigne   Montant total relié à une (des) opération(s)
mMontant_Solde            fntOPER_RDI_RechercherPaiements.mMontant_Solde     Le montant du paiement moins le montant assigné

Exemple d’appel     : EXECUTE [dbo].[psOPER_RDI_RechercherPaiements] NULL,'2010-01-27',NULL,'ALAIN PARADIS','1466245',NULL
                      exec psOPER_RDI_RechercherPaiements 'FRA','2015-01-01','2015-12-31',NULL,NULL,1
					  exec psOPER_RDI_RechercherPaiements 'FRA',NULL,NULL,NULL,NULL,1
					  exec psOPER_RDI_RechercherPaiements 'FRA',NULL,NULL,NULL,NULL,0

Historique des modifications:
        Date            Programmeur                         Description
        ------------    ---------------------------------- ---------------------------
        2010-02-15      Danielle Côté                       Création du service
		2012-01-18		Donald Huppé						glpi 6535 : Ne pas retourner les paiments qui sont remboursés
		2015-03-23		Donald Huppé						Refonte complète sans appel de la fonction fntOPER_RDI_RechercherPaiements pour plus de vitesse
        2016-05-16      Steeve Picard                       Ajout de 2 nouveaux champs retournés «tiID_RDI_Raison_Paiement» & «vcDescription_Raison»
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_RDI_RechercherPaiements]
(
   @cID_Langue         CHAR(3)
  ,@dtDate_Depot_Debut DATETIME
  ,@dtDate_Depot_Fin   DATETIME
  ,@vcNom_Deposant     VARCHAR(35)
  ,@vcNo_Document      VARCHAR(30)
  ,@tiNonAssigné       TINYINT
)
AS
BEGIN

   IF @cID_Langue IS NULL
      SET @cID_Langue = 'FRA'

   IF @tiNonAssigné IS NULL
      SET @tiNonAssigné = 0

	SELECT 
		PAI.iID_RDI_Depot
		,PAI.iID_RDI_Paiement
		,dtDate_Depot = DEP.dtDate_Depot
		,vcNom_Deposant = [dbo].[fnCONV_FormaterNom](PAI.vcNom_Deposant)
		,vcNo_Document = PAI.vcNo_Document
		,vcSouscripteur = hs.FirstName + ', ' + hs.LastName -- [dbo].[fn_Mo_HumanName](CON.subscriberID)-- --
		,PAI.vcNo_Oper
		,mMontant_Paiement = PAI.mMontant_Paiement_Final
		,mMontant_Assigne = isnull(mMontant_Assigne,0) --([dbo].[fnOPER_RDI_CalculerMontantAssignePaiement](PAI.iID_RDI_Paiement,NULL))
		,mMontant_Solde = PAI.mMontant_Paiement_Final - isnull(mMontant_Assigne,0) --([dbo].[fnOPER_RDI_CalculerMontantAssignePaiement](PAI.iID_RDI_Paiement,NULL)))
        ,PAI.tiID_RDI_Raison_Paiement
        ,PAI.vcDescription_Raison
	FROM tblOPER_RDI_Paiements PAI
	JOIN tblOPER_RDI_Depots DEP ON DEP.iID_RDI_Depot = PAI.iID_RDI_Depot
	LEFT JOIN dbo.Un_Convention CON ON RTRIM(LTRIM(CON.ConventionNo)) = PAI.vcNo_Document
	LEFT JOIN dbo.Mo_Human hs on con.SubscriberID = hs.HumanID
	LEFT JOIN (
		SELECT iID_RDI_Paiement , mMontant_Assigne = sum(mMontant_Assigne)
			FROM (
			--Une opération est dans Un_Cotisation    
			SELECT 
				rl.iID_RDI_Paiement
				,rl.OperID 
				,mMontant_Assigne = SUM(Ct.Cotisation + Ct.Fee + Ct.BenefInsur + Ct.SubscInsur + Ct.TaxOnInsur)
			FROM tblOPER_RDI_Liens rl
			JOIN Un_Cotisation ct on rl.OperID = ct.OperID
			GROUP BY rl.iID_RDI_Paiement,rl.OperID 

			UNION ALL

			-- et/ou peut-être une autre est dans Un_ConventionOPER
			SELECT 
				rl.iID_RDI_Paiement 
				,rl.OperID
				,mMontant_Assigne = sum(co.ConventionOperAmount) 
			FROM tblOPER_RDI_Liens rl 
			JOIN Un_ConventionOPER co on rl.OperID = co.OperID
			WHERE co.ConventionOperTypeID = 'INC'
			GROUP by rl.iID_RDI_Paiement ,rl.OperID

			) R
		GROUP BY iID_RDI_Paiement

		) o on o.iID_RDI_Paiement = pai.iID_RDI_Paiement
	WHERE 
		[dbo].[fnOPER_EDI_ObtenirStatutFichier](DEP.iID_EDI_Fichier) <> 'ERR'
			
		AND PAI.iID_RDI_Paiement NOT IN (SELECT iID_RDI_Paiement FROM tblOPER_RDI_Paiements_Rembourses)

		AND ((@dtDate_Depot_Debut IS NULL) OR (DEP.dtDate_Depot >= @dtDate_Depot_Debut))
		AND ((@dtDate_Depot_Fin   IS NULL) OR (DEP.dtDate_Depot <= @dtDate_Depot_Fin))
		AND ((@vcNom_Deposant     IS NULL) OR (PAI.vcNom_Deposant =  @vcNom_Deposant))
		AND ((@vcNo_Document      IS NULL) OR (PAI.vcNo_Document = @vcNo_Document))

		AND (
			(@tiNonAssigné = 1 AND PAI.mMontant_Paiement_Final - isnull(mMontant_Assigne,0) > 0)
			OR
			@tiNonAssigné = 0
			)
	ORDER BY DEP.dtDate_Depot, PAI.vcNom_Deposant, PAI.vcNo_Document

END

/*
   IF @tiNonAssigné = 1
   BEGIN
       SELECT PAI.iID_RDI_Depot as iID_RDI_Depot
             ,PAI.iID_RDI_Paiement as iID_RDI_Paiement
             ,DEP.dtDate_Depot as dtDate_Depot
             ,PAI.vcNom_Deposant as vcNom_Deposant
             ,PAI.vcNo_Document as vcNo_Document
             ,PAI.vcSouscripteur as vcSouscripteur
             ,PAI.vcNo_Oper as vcNo_Oper
             ,PAI.mMontant_Paiement as mMontant_Paiement
             ,PAI.mMontant_Assigne as mMontant_Assigne
             ,PAI.mMontant_Solde as mMontant_Solde
         FROM tblOPER_RDI_Depots DEP
             ,[dbo].[fntOPER_RDI_RechercherPaiements]() PAI
        WHERE DEP.iID_RDI_Depot = PAI.iID_RDI_Depot
          AND ((@dtDate_Depot_Debut IS NULL) OR (DEP.dtDate_Depot >= @dtDate_Depot_Debut))
          AND ((@dtDate_Depot_Fin   IS NULL) OR (DEP.dtDate_Depot <= @dtDate_Depot_Fin))
          AND ((@vcNom_Deposant     IS NULL) OR (PAI.vcNom_Deposant =  @vcNom_Deposant))
          AND ((@vcNo_Document      IS NULL) OR (PAI.vcNo_Document = @vcNo_Document))
          AND PAI.mMontant_Solde > 0
          
        /* glpi 6535 */ AND PAI.iID_RDI_Paiement NOT IN (SELECT iID_RDI_Paiement FROM tblOPER_RDI_Paiements_Rembourses)
          
        ORDER BY DEP.dtDate_Depot, PAI.vcNom_Deposant, PAI.vcNo_Document
   END
   ELSE
   BEGIN
       SELECT PAI.iID_RDI_Depot as iID_RDI_Depot
             ,PAI.iID_RDI_Paiement as iID_RDI_Paiement
             ,DEP.dtDate_Depot as dtDate_Depot
             ,PAI.vcNom_Deposant as vcNom_Deposant
             ,PAI.vcNo_Document as vcNo_Document
             ,PAI.vcSouscripteur as vcSouscripteur
             ,PAI.vcNo_Oper as vcNo_Oper
             ,PAI.mMontant_Paiement as mMontant_Paiement
             ,PAI.mMontant_Assigne as mMontant_Assigne
             ,PAI.mMontant_Solde as mMontant_Solde
        FROM tblOPER_RDI_Depots DEP
            ,[dbo].[fntOPER_RDI_RechercherPaiements]() PAI
       WHERE DEP.iID_RDI_Depot = PAI.iID_RDI_Depot
         AND ((@dtDate_Depot_Debut IS NULL) OR (DEP.dtDate_Depot >= @dtDate_Depot_Debut))
         AND ((@dtDate_Depot_Fin   IS NULL) OR (DEP.dtDate_Depot <= @dtDate_Depot_Fin))
         AND ((@vcNom_Deposant     IS NULL) OR (PAI.vcNom_Deposant =  @vcNom_Deposant))
         AND ((@vcNo_Document      IS NULL) OR (PAI.vcNo_Document = @vcNo_Document))
         
         /* glpi 6535 */ AND PAI.iID_RDI_Paiement NOT IN (SELECT iID_RDI_Paiement FROM tblOPER_RDI_Paiements_Rembourses)
         
       ORDER BY DEP.dtDate_Depot, PAI.vcNom_Deposant, PAI.vcNo_Document
   END

*/


