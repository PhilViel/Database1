
/****************************************************************************************************
Code de service		:		psGENE_InsererTitreNote
Nom du service		:		1.7.2	Insérer un Titre pré établi de note 
But					:		Créer une nouveau titre pré établi de note dans le système
Facette				:		SGRC 
Reférence			:		Système de gestion de la relation client

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
                        @vcTitreNote	            Titre pré établi de la note

Exemple d'appel:
                
Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
                       tblGENE_TitreNote	        iID_TitreNote

Historique des modifications :			
						Date						Programmeur								Description							Référence
						2009-04-23					D.T.									Création
 ****************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_InsererTitreNote]
                                  (	
									@vcTitreNote varchar(128)
                                  )
AS
BEGIN
	INSERT INTO dbo.tblGENE_TitreNote (vcTitreNote, cCodeTitre)
		OUTPUT INSERTED.iID_TitreNote
	SELECT  @vcTitreNote, NULL
	RETURN
END
