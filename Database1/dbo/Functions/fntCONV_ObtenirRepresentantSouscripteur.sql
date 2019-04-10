
/****************************************************************************************************
Code de service		:		fnCONV_ObtenirRepresentantSouscripteur
Nom du service		:		Obtenir les responsable de la convention  
But					:		Récupérer les données du représentant d’une convention et de son directeur
Facette				:		P171U
Reférence			:		Relevé de dépôt
Parametres d'entrée :	Parametres					Description                              Obligatoir
                        ----------                  ----------------                         --------------                       
                        iIDConvention	            Identifiant unique de la convention      Oui

Exemple d'appel:
                
                SELECT * FROM fntCONV_ObtenirRepresentantSouscripteur(154833)

Parametres de sortie :  Table						Champs										Description
					    -----------------			---------------------------					--------------------------
                        Mo_Human	                iIDRep	                                    Identifiant de l’humain du représentant
						Mo_Human	                vcPrenomRep	                                Prénom du représentant
						Mo_Human	                vcNomRep	                                Nom du représentant
						Mo_Adr	                    vcTelRep	                                Numéro de téléphone du représentant
						Mo_Human	                iIDDir	                                    Identifiant de l’humain du directeur
						Mo_Human	                vcPrenomDir	                                Prénom du directeur
						Mo_Human	                vcNomDir	                                Nom du directeur
						Mo_Adr	                    vcTelDir	                                Numéro de téléphone du directeur

Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2008-12-03					Fatiha Araar							Création de la fonction           
						2010-07-07					Jean-François Gauthier					Modification afin de retourner "Head Office" 
																							au lieu de "Siège Social" pour le représentant
																							si la langue est anglaise
						2011-03-25					Pierre-Luc Simard						Ajout de l'adresse courriel.
						2014-10-17					Donald Huppé							Tel = phone2, sinon phone1

/* 
	- On devrait retourner l'ID du directeur au lieu de l'ID du représentant si ce dernier est inactif? 
	- Pourquoi retourner le numéro de convention?
	- On pourrait aussi permettre l;a recherche à partir du numéro de souscripteur?
*/

 ****************************************************************************************************/

CREATE FUNCTION [dbo].[fntCONV_ObtenirRepresentantSouscripteur]
						(@iIDConvention INT)

RETURNS TABLE 
AS 
RETURN
(	
		SELECT 
			iIDRep		=	R.RepID, --l'id du representant
			vcPrenomRep =	CASE 
								WHEN R.BusinessEnd IS NULL 
									THEN 
										CASE 
											WHEN HS.LangId = 'ENU' AND ISNULL(H.FirstName,'') = 'Siège' AND ISNULL(H.LastName,'') = 'Social' THEN 'Head'
											ELSE ISNULL(H.FirstName,'') 
										END
								ELSE 
										CASE 
											WHEN HS.LangId = 'ENU' AND ISNULL(HD.FirstName,'')  = 'Siège' AND ISNULL(HD.FirstName,'')  = 'Social' THEN 'Head'
											ELSE ISNULL(HD.FirstName,'')  
										END
							END,--le prenom du representant
			vcNomRep	=	CASE 
								WHEN R.BusinessEnd IS NULL 
									THEN 
										CASE 
											WHEN HS.LangId = 'ENU' AND ISNULL(H.FirstName,'') = 'Siège' AND ISNULL(H.LastName,'') = 'Social' THEN 'Office'
											ELSE ISNULL(H.LastName,'')  
										END										
								ELSE 
										CASE 
											WHEN HS.LangId = 'ENU' AND ISNULL(HD.FirstName,'') = 'Siège' AND ISNULL(HD.LastName,'') = 'Social' THEN 'Office'
											ELSE ISNULL(HD.LastName,'')  
										END	
							END,--le nom du representant
			vcTelRep	=	CASE 
								WHEN R.BusinessEnd IS NULL THEN ISNULL(ISNULL(A.Phone2,A.Phone1),'') 
								ELSE ISNULL(ISNULL(AD.Phone2,AD.Phone1),'') 
							END,--le téléphone du representant
			vcCourrielRep =	CASE 
								WHEN R.BusinessEnd IS NULL THEN ISNULL(A.Email,'') 
								ELSE ISNULL(AD.Email,'') 
							END,--le courriel du representant
			
			iIDDir		=	RD.BossID,--l'id du directeur
			vcPrenomDir =	ISNULL(HD.FirstName,''),--le prenom du directeur
			vcNomDir	=	ISNULL(HD.LastName,''),--le nom du directeur
			vcTelDir	=	ISNULL(ISNULL(AD.Phone2,AD.Phone1),''),--le téléphone du directeur
            conventionid =	C.ConventionID
		 FROM 
			dbo.Un_Convention C
			INNER JOIN dbo.Un_Subscriber S 
				ON C.SubscriberID = S.SubscriberID
			INNER JOIN dbo.Mo_Human HS
				ON S.SubscriberID = HS.HumanID
			LEFT OUTER JOIN dbo.Un_Rep R 
				ON S.RepID = R.RepID
			LEFT OUTER JOIN dbo.Mo_Human H 
				ON H.HumanID = R.RepID
			LEFT OUTER JOIN dbo.Mo_Adr A 
				ON A.AdrID = H.AdrID
			LEFT OUTER JOIN (
							SELECT	RB.RepID,
								BossID = MAX(BossID)
							FROM 
								dbo.Un_RepBossHist RB
								JOIN (	SELECT 
											RB.RepID,
											RepBossPct = MAX(RB.RepBossPct)
										FROM 
											dbo.Un_RepBossHist RB
										WHERE 
											RepRoleID = 'DIR'
											AND RB.StartDate <= GETDATE()
											AND ISNULL(RB.EndDate,GETDATE()) >= GETDATE()
										GROUP BY RB.RepID) MRB 
								ON MRB.RepID = RB.RepID AND MRB.RepBossPct = RB.RepBossPct
						WHERE 
							RB.RepRoleID = 'DIR'
							AND 
							RB.StartDate <= GETDATE()
							AND 
							ISNULL(RB.EndDate,GETDATE()) >= GETDATE()
						GROUP BY 
							RB.RepID)RD 
								ON RD.RepID = H.HumanID
			LEFT OUTER JOIN dbo.Mo_Human HD 
				ON HD.HumanID = RD.BossID
			LEFT OUTER JOIN dbo.Mo_Adr AD 
				ON AD.AdrID = HD.AdrID
        WHERE 
			C.ConventionID = @iIDConvention
    )


