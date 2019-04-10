


/****************************************************************************************************
Code de service		:		fnGENE_CalculerJVMComptableFixe_Convention
Nom du service		:		CalculerJVMComptable_Convention
But					:		Calculer la juste valeur marchande (JVM) comptable
Facette				:		GENE
Reférence			:		Système de gestion de la relation client

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
                        iID_Convention              ID de la convention concernée par l'appel
                        dtDate_Fin                  Date de fin de la période considérée par l'appel


Exemple d'appel:
                SELECT * FROM DBO.[fnGENE_CalculerJVMComptableFixe_Convention] (1234, 2011-12-19 07:52:45.930)

Parametres de sortie : La JVM comptable

Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2012-07-24                  Dominique Pothier                       Création de la fonction
						2013-08-07					Stéphane Barbeau						@mMontant_Interets_Rendements: Correction Code TIQ pour IIQ
																							@mMontant_Cotisations: AND ct.EffectDate<= @dtDate_Fin
 ****************************************************************************************************/
 
CREATE FUNCTION [dbo].[fnGENE_CalculerJVMComptableFixe_Convention]
					(	
	                        @iID_Convention 				INT,
							@dtDate_Fin  				DATETIME
					)
RETURNS  money
AS
BEGIN
DECLARE 
		@mMontant_Cotisations money ,
		@mMontant_Interets_Rendements money ,
		@mMontant_SCEE money ,
		@mMontant_BEC money,
		@mMontant_IQEE money ,
		@mMontant_SubventionProvinciale money,
		@mMontant_Somme money 


		set @mMontant_Cotisations  = 0
		set @mMontant_Interets_Rendements  = 0
		set @mMontant_SCEE  = 0
		set @mMontant_BEC  = 0
		set @mMontant_IQEE  = 0
		set @mMontant_SubventionProvinciale  = 0
		set @mMontant_Somme  = 0

SELECT @mMontant_Cotisations = SUM(ISNULL(ct.Cotisation,0))
FROM dbo.Un_Cotisation ct
	JOIN dbo.Un_Unit un on ct.UnitID = un.UnitID
	JOIN dbo.Un_Convention conv on un.ConventionID = conv.ConventionID 
WHERE conv.ConventionID = @iID_Convention
	  AND ct.EffectDate<= @dtDate_Fin

SELECT @mMontant_Interets_Rendements = SUM(ISNULL(co.ConventionOperAmount,0))
FROM dbo.Un_ConventionOper co
	JOIN dbo.Un_Oper op on co.OperID = op.OperID
Where co.ConventionID = @iID_Convention
	AND op.OperDate <= @dtDate_Fin
	AND co.ConventionOperTypeID IN ('IBC','ICQ','III','IIQ','IMQ','INM','INS','IQI','IS+','IST','ITR','MIM')

SELECT @mMontant_SCEE = dbo.fnPCEE_CalculerSoldeSCEE_Convention(@iID_Convention, @dtDate_Fin)

SELECT @mMontant_BEC = dbo.fnPCEE_CalculerSoldeBEC_Convention(@iID_Convention, @dtDate_Fin)

SELECT @mMontant_IQEE = dbo.fnIQEE_CalculerSoldeFixeIQEE_Convention(@iID_Convention, @dtDate_Fin)

SELECT @mMontant_SubventionProvinciale = SUM(ISNULL(cesp.Fpg,0))
FROM dbo.Un_CESP cesp
where cesp.ConventionID = @iID_Convention

set @mMontant_Somme = (@mMontant_Cotisations + @mMontant_Interets_Rendements + @mMontant_SCEE + @mMontant_BEC 
                   + @mMontant_IQEE + @mMontant_SubventionProvinciale + @mMontant_Somme)

RETURN ISNULL(@mMontant_Somme,0)
END

