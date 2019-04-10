/****************************************************************************************************
Code de service		:		fnGENE_EvaluerRegEx
Nom du service		:		Ce service est utilisé pour valider des expressions régulières
But					:		Valider des expressions régulières
Facette				:		GENE
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						@vcRegEx					Expression régulière de référence
						@vcValeur					Valeur à valider
						@bRespecterCasse			= 0 : ne respecte pas la casse, = 1 : respecte la casse

Exemple d'appel:
                
                SELECT dbo.fnGENE_EvaluerRegEx('[a-zA-Z0-9_\-]+@([a-zA-Z0-9_\-]+\.)+(com|org|edu|nz|au|fr|ca|net)','akitajfg@yahoo.fr',0)

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					-----------------------------
						N/A							@bMatch										= 1, si valide 0 sinon	
													
Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-07-15					Jean-François Gauthier					Création de la fonction
 ****************************************************************************************************/
CREATE FUNCTION dbo.fnGENE_EvaluerRegEx (
											@vcRegEx			VARCHAR(256),
											@vcValeur			VARCHAR(8000),
											@bRespecterCasse	BIT
										  )
RETURNS INT
AS
	BEGIN
			DECLARE	@iObj	INT, 
					@iRes	INT, 
					@bMatch	BIT

			SET @bMatch=0

			EXECUTE @iRes = sp_OACreate 'VBScript.RegExp', @iObj OUT
			IF (@iRes <> 0) 
				BEGIN
					RETURN NULL
				END
				
			EXECUTE @iRes = sp_OASetProperty @iObj, 'Pattern', @vcRegEx
			IF (@iRes <> 0)
				BEGIN
					RETURN NULL
				END
				
			EXECUTE @iRes = sp_OASetProperty @iObj, 'IgnoreCase', @bRespecterCasse
			IF (@iRes <> 0) 
				BEGIN
					RETURN NULL
				END

			EXECUTE @iRes = sp_OAMethod @iObj, 'Test',@bMatch OUT, @vcValeur
			IF (@iRes <> 0) 
				BEGIN
					RETURN NULL
				END
			
			EXECUTE @iRes = sp_OADestroy @iObj

			RETURN @bMatch
	END
