
/****************************************************************************************************
Code de service		:		fnIQEE_CalculerSoldeFixeIQEE_Convention
Nom du service		:		CalculerSoldeTempsReelIQEE_Convention
But					:		Calculer le solde de l'IQÉÉ de base d'une convention
Facette				:		IQÉÉ
Reférence			:		Système de gestion de la relation client

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
                        iID_Convention              ID de la convention concernée par l'appel
                        dtDate_Fin                  Date de fin de la période considérée par l'appel


Exemple d'appel:
                SELECT * FROM DBO.[fnIQEE_CalculerSoldeFixeIQEE_Convention] (1234, 2011-12-19 07:52:45.930)

Parametres de sortie : Le solde de l'IQEE

Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2012-08-06                  Stéphane Barbeau                        Création de la fonction

****************************************************************************************************/

CREATE FUNCTION [dbo].[fnIQEE_CalculerSoldeFixeIQEE_Convention]( @iID_Convention INT, @dtDate_Fin DATETIME)
RETURNS MONEY
AS
BEGIN

	DECLARE @mMontant_IQEE Money;
	DECLARE @mIQEE_Majoration Money;
	DECLARE @mIQEE_Crédit_de_base Money;


	SET @mIQEE_Majoration = [dbo].[fnIQEE_CalculerSoldeFixe_Majoration_Convention](@iID_Convention, @dtDate_Fin)
	
	SET @mIQEE_Crédit_de_base = [dbo].[fnIQEE_CalculerSoldeFixe_CreditBase_Convention](@iID_Convention, @dtDate_Fin)


	SET @mMontant_IQEE = @mIQEE_Crédit_de_base + @mIQEE_Majoration
	
	RETURN @mMontant_IQEE

END


