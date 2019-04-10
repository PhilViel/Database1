
/****************************************************************************************************
Code de service		:		fnTEST_CreerOperationFinanciere
Nom du service		:		CreerOperationFinanciere
But					:		Obtenir l'ID d'une nouvelle opération financière
Facette				:		TEST
Reférence			:		TEST

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						@iID_Connexion int ,		Id de l'utilisateur.  Référence select humanID from mo_human where firstname like 'St%' and lastname = 'Barbeau' 
						@cID_Type_Operation			Type d'opération financière. Référence: select distinct OP.OperTypeID FROM un_oper OP
						@dtDate_Paiement			Date de paiement

Exemple d'appel:
                EXECUTE  DBO.[psTEST_CreerOperationFinanciere] (628022, 'PAE', getdate())

Parametres de sortie : L'ID de l'opération 

Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2014-03-12                  Stéphane Barbeau                        Création de la fonction

****************************************************************************************************/

CREATE PROCEDURE dbo.psTEST_CreerOperationFinanciere ( @iID_Connexion int ,@cID_Type_Operation char(3), @dtDate_Paiement datetime)

AS
BEGIN

	DECLARE @iID_Operation int
	
	EXECUTE @iID_Operation = [dbo].[SP_IU_UN_Oper] @iID_Connexion, 0,  @cID_Type_Operation, @dtDate_Paiement
	
	RETURN @iID_Operation

END


