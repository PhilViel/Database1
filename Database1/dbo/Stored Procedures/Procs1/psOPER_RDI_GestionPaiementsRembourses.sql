/****************************************************************************************************
Copyrights (c) 2012 Gestion Universitas inc.

Code du service : psOPER_RDI_GestionPaiementsRembourses
Nom du service  : Gestion des paiements remboursée au client.
But             : Patch qui permet d'inscrire les paiements qu'on veut voir disparaitre de l'écran des versements RDI.
				  Le dataset retournée présente la liste complète des paiements retiré de l'écran des versements RDI.
Facette         : OPER

Paramètres d’entrée :
Paramètre                  Description
-------------------------- --------------------------------------------------------------------------
@iID_RDI_PaiementRembourses_Ajout :  iID_RDI_Paiement à retirer de l'écran 
@iID_RDI_PaiementRembourses_Retrait : iID_RDI_Paiement à remettre dans l'écran

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

Exemple d’appel     :  exec psOPER_RDI_GestionPaiementsRembourses NULL, NULL, NULL

Historique des modifications:
        Date            Programmeur                         Description
        ------------    ----------------------------------	---------------------------
        2012-01-17      Donald Huppé						Création du service
		2012-02-08		Donald Huppé						ajout du paramètre "mot de passe"
		2015-03-23		Donald Huppé						Refonte complète sans appel de la fonction fntOPER_RDI_RechercherPaiements pour plus de vitesse
		2016-01-13		Donald Huppé						Modif du : insert INTO tblOPER_RDI_Paiements_Rembourses.
															C'est après avoir ajouté le champ "DateInserted" dans la table tblOPER_RDI_Paiements_Rembourses
**************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_RDI_GestionPaiementsRembourses]
(
  @iID_RDI_PaiementRembourses_Ajout int = NULL,
  @iID_RDI_PaiementRembourses_Retrait int = NULL,
  @MotDePasse varchar(20) = NULL
)
AS
BEGIN

     declare @ValeurDuMotDePasse varchar(20)
     
     set @ValeurDuMotDePasse = 'hjk678'
        
	IF @iID_RDI_PaiementRembourses_Ajout is not null and @MotDePasse = @ValeurDuMotDePasse
	AND NOT EXISTS (SELECT 1 FROM tblOPER_RDI_Paiements_Rembourses WHERE iID_RDI_Paiement = @iID_RDI_PaiementRembourses_Ajout)
	BEGIN
	
		insert INTO tblOPER_RDI_Paiements_Rembourses (iID_RDI_Paiement) VALUES( @iID_RDI_PaiementRembourses_Ajout)
	
	END	        
        
	IF @iID_RDI_PaiementRembourses_Retrait is not null and @MotDePasse = @ValeurDuMotDePasse
	BEGIN
	
		DELETE tblOPER_RDI_Paiements_Rembourses WHERE iID_RDI_Paiement = @iID_RDI_PaiementRembourses_Retrait
	
	END	      
        
     /*   
        
	SELECT 
		  PAI.iID_RDI_Depot as iID_RDI_Depot
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
	 AND PAI.mMontant_Solde > 0
	AND PAI.iID_RDI_Paiement IN (select iID_RDI_Paiement from tblOPER_RDI_Paiements_Rembourses)
      */
	  
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
        ,mMontant_Solde = PAI.mMontant_Paiement_Final - isnull(mMontant_Assigne,0) 
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
		AND PAI.iID_RDI_Paiement IN (SELECT iID_RDI_Paiement FROM tblOPER_RDI_Paiements_Rembourses)
		AND PAI.mMontant_Paiement_Final - isnull(mMontant_Assigne,0) > 0
	ORDER BY DEP.dtDate_Depot, PAI.vcNom_Deposant, PAI.vcNo_Document	  
	  
End


