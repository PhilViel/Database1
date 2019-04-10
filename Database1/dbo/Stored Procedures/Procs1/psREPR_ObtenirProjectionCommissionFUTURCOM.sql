
/****************************************************************************************************
Code de service		:		psREPR_ObtenirProjectionCommissionFUTURCOM
Nom du service		:		
But					:		GLPI 5657 : Obtenir les données FUTURCOM à partir des projections de commission. utilisé dans rapport RapCommission_CrossTAB_GroupePaie.rdl
Description			:		

Facette				:		REPR
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------

Exemple d'appel:	

		exec psREPR_ObtenirProjectionCommissionFUTURCOM
		
Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------

Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2011-07-13					Donald Huppé							Création
						2011-10-07					Donald Huppé							glpi 6188 : Ajout de FuturComWithoutCoverdAdvance
						2013-10-18					Donald Huppé							glpi 10391 : Enlever le Avant et Après, Ajouter la date de calcul des projection :RepProjectionTreatmentDate
						2013-12-06					Donald Huppé							Ajouter le RepCode en integer : RepCodeINT

 ****************************************************************************************************/

CREATE PROCEDURE [dbo].[psREPR_ObtenirProjectionCommissionFUTURCOM]

AS
	BEGIN
	
	declare @RepProjectionTreatmentDate datetime
	
	select @RepProjectionTreatmentDate = RepProjectionTreatmentDate  from un_def
	
	SELECT 
		R.RepID,
		P.RepCode,
		RepProjectionDate,
		RepName = hR.lastname + ' ' + hR.firstname, 
		R.businessStart,
		R.businessEnd,
		--Periode = case when FirstDepositDate < '2011-01-01' then '1-Avant' else '2-Après' end,
		FuturCom = sum(PeriodComm + CoverdAdvance),
		FuturComWithoutCoverdAdvance = sum(PeriodComm)
		,RepProjectionTreatmentDate = LEFT(CONVERT(VARCHAR, @RepProjectionTreatmentDate, 120), 10)
		,RepCodeINT = CAST(P.RepCode AS int)
	FROM 
		Un_RepProjection P
		JOIN Un_Rep R ON P.RepID = R.RepID
		JOIN dbo.Mo_Human HR ON R.RepID = HR.HumanID
		
	WHERE R.RepID <> 149876
	GROUP BY 
		R.RepID,
		P.RepCode,
		RepProjectionDate,
		hR.lastname + ' ' + hR.firstname, 
		R.businessStart,
		R.businessEnd
		,CAST(P.RepCode AS int)
		--,case when FirstDepositDate < '2011-01-01' then '1-Avant' else '2-Après' end
	ORDER BY 
		P.RepCode,
		RepProjectionDate
		--,case when FirstDepositDate < '2011-01-01' then '1-Avant' else '2-Après' end
	
	END

