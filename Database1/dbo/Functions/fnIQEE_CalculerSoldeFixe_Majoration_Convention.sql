
/****************************************************************************************************
Code de service		:		fnIQEE_CalculerSoldeFixe_Majoration_Convention
Nom du service		:		CalculerSoldeFixe_IQEE_Convention
But					:		Calculer le solde Fixe de l'IQÉÉ+ d'une convention.  Compte tenu que nous traitons des données dans le passé, il faut retourner la valeur du solde à l'époque.
Facette				:		IQÉÉ
Reférence			:		Système de gestion de la relation client

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
                        iID_Convention              ID de la convention concernée par l'appel
                        dtDate_Fin                  Date de fin de la période considérée par l'appel


Exemple d'appel:
                SELECT * FROM DBO.[fnIQEE_CalculerSoldeFixe_Majoration_Convention] (1234, 2011-12-19 07:52:45.930)

Parametres de sortie : Le solde de l'IQEE

Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2012-08-06                  Stéphane Barbeau                        Création de la fonction

****************************************************************************************************/

CREATE FUNCTION [dbo].[fnIQEE_CalculerSoldeFixe_Majoration_Convention]( @iID_Convention INT, @dtDate_Fin DATETIME)
RETURNS MONEY
AS
BEGIN

	DECLARE @mMontant_IQEE_Majoration Money;



	SELECT @mMontant_IQEE_Majoration = ISNULL(SUM(co.ConventionOperAmount),0)
	FROM Un_ConventionOper co
		JOIN dbo.Un_Oper op on co.OperID = op.OperID
	Where co.ConventionID = @iID_Convention
		AND op.OperDate <= @dtDate_Fin
		AND co.ConventionOperTypeID IN ('MMQ')

		RETURN @mMontant_IQEE_Majoration

END


