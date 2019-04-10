/****************************************************************************************************
Copyrights (c) 2015 Gestion Universitas inc
Nom                 :	psOPER_RapportRDIEnCirculation
Description         :	Pour le rapport SSRS "RapportRDIEnCirculation"
Valeurs de retours  :	Dataset 
Note                :	2015-03-25	Donald Huppé			Créaton

						2015-05-13	Donald Huppé			Ajout des RDI renversés
						2015-09-10	Donald Huppé			GLPI 15552 : Gestion des paiements de INC
						2015-11-27	Donald Huppé			Enlever le groupe sur conventionNo, et le mettre à NULL
						2016-01-13	Donald Huppé			glpi 16423 : ajustement pour retrouver les opération RDI effectuées avant @EnDateDu
															gestion des paiements remboursés : on valide la date DateInserted
															Exclure les paiements renversés
exec psOPER_RapportRDIEnCirculation '2015-12-31'
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_RapportRDIEnCirculation] 
	(
	@EnDateDu DATETIME
	) 

as
BEGIN

set ARITHABORT ON


	SELECT DISTINCT
		DateCreationImporation = fic.dtDate_Creation
		,StastutDepot = sd.vcDescription
		,d.dtDate_Depot
		,vcNo_Document = ltrim(rtrim(p.vcNo_Document))
		,vcNo_Oper = ltrim(rtrim(p.vcNo_Oper))
		,vcNom_Deposant = ltrim(rtrim(p.vcNom_Deposant))
		--,p.mMontant_Paiement
		,MontantDeposeParLeDeposant = p.mMontant_Paiement - isnull(DejaAssign.MontantDejaAssigne,0)  - ISNULL(MontantINCDejaAssigne,0)-- c'est plutot le montant qui n'a pas été appliqué. Le nom du champ n'est pas bon
		,d.mMontant_Depot
		,ConventionNo = NULL
		,p.iID_RDI_Paiement
		,OperTypeID = NULL
		,OperDate = NULL


	FROM 
		tblOPER_RDI_Depots D
		JOIN tblOPER_EDI_Fichiers FIC ON FIC.iID_EDI_Fichier = d.iID_EDI_Fichier
		JOIN tblOPER_RDI_Paiements P ON P.iID_RDI_Depot = D.iID_RDI_Depot
		JOIN tblOPER_RDI_StatutsDepot sd on sd.tiID_RDI_Statut_Depot = d.tiID_RDI_Statut_Depot

		LEFT JOIN tblOPER_RDI_Paiements_Rembourses pr on pr.iID_RDI_Paiement = p.iID_RDI_Paiement and isnull(pr.DateInserted,'1900-01-01') <= @EnDateDu

		--LEFT JOIN (
		--	select p.iID_RDI_Paiement
		--	from tblOPER_RDI_Paiements P
		--	JOIN tblOPER_RDI_Liens L ON L.iID_RDI_Paiement = P.iID_RDI_Paiement
		--	join Un_OperCancelation OC ON OC.OperID = L.OperID
		--	JOIN Un_Oper OCancel on OC.OperID = OCancel.OperID and OCancel.OperDate <= @EnDateDu
		--	group by p.iID_RDI_Paiement
		--	)RDI_PaiementRenverse on RDI_PaiementRenverse.iID_RDI_Paiement = p.iID_RDI_Paiement


		LEFT JOIN (
			select p.iID_RDI_Paiement, MontantDejaAssigne = sum(ct.Cotisation + ct.Fee + ct.BenefInsur + ct.SubscInsur + ct.TaxOnInsur)
			from tblOPER_RDI_Paiements P
			JOIN tblOPER_RDI_Liens L ON L.iID_RDI_Paiement = P.iID_RDI_Paiement
			JOIN un_oper o on O.OperID = L.OperID
			JOIN Un_Cotisation ct on o.OperID = ct.OperID
			where o.OperDate <=@EnDateDu
			group by p.iID_RDI_Paiement
			)DejaAssign on DejaAssign.iID_RDI_Paiement = p.iID_RDI_Paiement

		LEFT JOIN (
			select p.iID_RDI_Paiement, MontantINCDejaAssigne = SUM(CO.ConventionOperAmount)
			from tblOPER_RDI_Paiements P
			JOIN tblOPER_RDI_Liens L ON L.iID_RDI_Paiement = P.iID_RDI_Paiement
			JOIN un_oper o on O.OperID = L.OperID
			JOIN Un_ConventionOper CO on o.OperID = CO.OperID
			where o.OperDate <=@EnDateDu
				and CO.ConventionOperTypeID = 'INC'
			group by p.iID_RDI_Paiement
			)INCDejaAssign on INCDejaAssign.iID_RDI_Paiement = p.iID_RDI_Paiement

	where  1=1
		and LEFT(CONVERT(VARCHAR, fic.dtDate_Creation, 120), 10) <= @EnDateDu
		
		--and RDI_PaiementRenverse.iID_RDI_Paiement is NULL -- n'est pas un paiement renversé

		and pr.iID_RDI_Paiement is null -- exclure les paiement remboursés
		and not (d.tiID_RDI_Statut_Depot = 3 and yeaR(d.dtDate_Depot) = 2011) -- Exclure ces cas du début du projet RDI
		and (p.mMontant_Paiement - isnull(DejaAssign.MontantDejaAssigne,0) - ISNULL(MontantINCDejaAssigne,0) ) <> 0 -- il reste du $$$ en circulation


	ORDER by vcNo_Oper

set ARITHABORT OFF

	END
