
/****************************************************************************************************
Code de service		:		fnCONV_ObtenirMontantSouscritConvention
Nom du service		:		Obtenir le montant souscrit d’une convention 
But					:		Récupérer le montant souscrit d’une convention 
Facette				:		P171U
Reférence			:		Relevé de dépôt
Parametres d'entrée :	Parametres					Description                              Obligatoir
                        ----------                  ----------------                         --------------                       
                        iIDConvention	            Identifiant unique de la convention      Oui
						dtDateDebut	                Date de début                            Non
						dtDateFin	                Date de fin                              Non
						
Exemple d'appel:
                select dbo.[fnCONV_ObtenirMontantSouscritConvention] (291277,NULL,'2008-12-31')
                
Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
                       S/O                          @mMntSouscrit                               le montant souscrit
                    
Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2008-12-09					Fatiha Araar							Création de la fonction           
						2009-07-24					Jean-François Gauthier					Modification pour UnitQty qui doit être obtenu
																							à partir d'une fonction plutôt qu'à partir de la
																							table Un_Unit
						2009-09-22					Jean-François Gauthier					Retour à l'ancienne méthode pour obtenir UnitQty
 ****************************************************************************************************/

CREATE FUNCTION [dbo].[fnCONV_ObtenirMontantSouscritConvention]
							(
								@iIDConvention INT,
								@dtDateDebut DATETIME ,
								@dtDateFin DATETIME  
							)
RETURNS MONEY
AS
	BEGIN
		DECLARE @mMntSouscrit MONEY
			
		  SELECT @mMntSouscrit = SUM(CASE
									WHEN ISNULL(SS.bIsContestWinner,0) = 1 THEN 0
									WHEN P.PlanTypeID = 'IND' THEN ISNULL(V2.Cotisation,0)
									WHEN ISNULL(Co.ConnectID,0) = 0 THEN 
										(ROUND(U.UnitQty * M.PmtRate,2) * M.PmtQty) + U.SubscribeAmountAjustment
									ELSE ISNULL(V1.CotisationFee,0) + U.SubscribeAmountAjustment
								END)
		  FROM 
				dbo.Un_Convention C
				INNER JOIN dbo.fntCONV_ObtenirUnitesConvention(@iIDConvention, @dtDateDebut, @dtDateFin) U 
					ON U.ConventionID = C.ConventionID
				INNER JOIN dbo.Un_Modal M 
					ON M.ModalID = U.ModalID
				INNER JOIN dbo.Un_Plan P 
					ON P.PlanID = C.PlanID
				LEFT OUTER JOIN dbo.Mo_Connect Co 
					ON Co.ConnectID = U.PmtEndConnectID AND Co.ConnectStart BETWEEN ISNULL(@dtDateDebut,'1900/01/01') AND ISNULL(@dtDateFin,GETDATE())
				LEFT OUTER JOIN dbo.Un_SaleSource SS 
					ON SS.SaleSourceID = U.SaleSourceID
				LEFT OUTER JOIN (
									SELECT 
										U.UnitID,CotisationFee = SUM(Ct.Cotisation + Ct.Fee)
									FROM 
										dbo.Un_Unit U
										INNER JOIN dbo.Un_Cotisation Ct 
											ON Ct.UnitID = U.UnitID
										INNER JOIN dbo.Un_Oper O 
											ON O.OperID = Ct.OperID
									WHERE 
										U.ConventionID = @iIDConvention
										AND 
										O.OperDate BETWEEN ISNULL(@dtDateDebut,'1900/01/01') AND ISNULL(@dtDateFin,GETDATE())
									GROUP BY 
										U.UnitID
								) V1 ON V1.UnitID = U.UnitID
				LEFT OUTER JOIN (
									SELECT 
										U.UnitID, Cotisation = SUM(Ct.Cotisation)
									FROM 
										dbo.Un_Unit U
										INNER JOIN Un_Cotisation Ct 
											ON Ct.UnitID = U.UnitID
										INNER JOIN Un_Oper O 
											ON O.OperID = Ct.OperID
									WHERE 
										U.ConventionID = @iIDConvention
										AND 
										U.TerminatedDate IS NULL
										AND 
										U.IntReimbDate IS NULL
										AND 
										O.OperDate BETWEEN ISNULL(@dtDateDebut,'1900/01/01') AND ISNULL(@dtDateFin,GETDATE())
									GROUP BY 
										U.UnitID
								) V2 ON V2.UnitID = U.UnitID
			WHERE 
				C.ConventionID = @iIDConvention

		RETURN @mMntSouscrit
	END
