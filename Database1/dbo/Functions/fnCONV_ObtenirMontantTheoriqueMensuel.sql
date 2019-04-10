
/****************************************************************************************************
Code de service		:		fnCONV_ObtenirMontantTheoriqueMensuel
Nom du service		:		
But					:		Obtenir le montant théorique pour la convention et l'unité mentionnée si elle est précisée
Facette				:		CONV
Reférence			:		Relevé de dépôt

Parametres d'entrée :	Parametres					Description                              Obligatoir
                        ----------                  ----------------                         --------------                       
                        iIDConvention	            Identifiant unique de la convention      Oui
						iIDUnite					Identifiant unique de l'unité			 Non, si NULL, le montant retournée sera la somme pour toute les unités
                        dtDateDebut					Date de début du calcul					 Non
						dtDateFin					Date de fin du calcul					 Oui



Exemple d'appel:
                SELECT dbo.fnCONV_ObtenirMontantTheoriqueMensuel(335594, 508392, '2009-01-01', '2009-12-31')


Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
                       S/O	                        @mMontantTheoMens							Montant théorique mensuel de la convention

                    
Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-11-27					Jean-François Gauthier					Création de la fonction           
						
 ****************************************************************************************************/

CREATE FUNCTION [dbo].[fnCONV_ObtenirMontantTheoriqueMensuel]
					( 
						@iIDConvention	INT
						,@iIDUnite		INT
						,@dtDateDebut	DATETIME
						,@dtDateFin		DATETIME
					)	
						
RETURNS MONEY
AS
	BEGIN
		DECLARE @mMontantTheoMens MONEY
 
		SELECT 
			@mMontantTheoMens = SUM(ROUND(M.PmtRate * U.UnitQty, 3))
		FROM 
			dbo.Un_Unit U 
			INNER JOIN dbo.Un_Modal M 
				ON U . ModalID = M.ModalID
			LEFT OUTER JOIN (
							SELECT	
								U.UnitID,
								CotisationFee = SUM(Ct.Fee + Ct.Cotisation)
							FROM 
								dbo.Un_Unit U
								INNER JOIN Un_Cotisation Ct 
									ON U.UnitID = Ct.UnitID
							WHERE 
								U.ConventionID = @iIDConvention
								AND 
								Ct.EffectDate between ISNULL(@dtDateDebut,'1900-01-01') and @dtDateFin
							GROUP BY 
								U.UnitID
							) Ct ON U.UnitID = Ct.UnitID
		WHERE 
			U.ConventionID	= @iIDConvention
			AND
			U.UnitID		= ISNULL(@iIDUnite, U.UnitID)
			AND 
			ISNULL(Ct.CotisationFee, 0) < M.PmtQty * ROUND (M.PmtRate * U.UnitQty, 2)

		RETURN @mMontantTheoMens
	END
