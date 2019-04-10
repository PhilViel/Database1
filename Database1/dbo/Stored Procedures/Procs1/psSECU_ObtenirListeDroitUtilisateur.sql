/****************************************************************************************************
 * Copyrights (c) 2008 Gestion Universitas inc
 * 
 * Code du service             : psSECU_ObtenirListeDroitUtilisateur
 * Nom du service              : Obtenir la liste des droits d'un utilisateur
 * But                         : Obtenir la liste des droits d'un utilisateur
 * Facette                     : SECU
 * Reférence                   : 
 * 
 * Exemple d'appel			
 *					EXEC [dbo].[psSECU_ObtenirListeDroitUtilisateur] 546659
 *					EXEC [dbo].[psSECU_ObtenirListeDroitUtilisateur] 149485
 * Parametre d'entrée          : Parametre                           Description 
 *                               ----------------------------------- ------------------------------------
 *                               @iID_Utilisateur                    UserID de l'utilisateur
 *                               
 *                                                                   
 *
 * Parametre de sortie         : Parametre                           Description 
 *                               ----------------------------------- ------------------------------------
 *                               
 * 
 * Historique des modification : Date       Programmeur              Description                          Référence
 *                               ---------- ------------------------ ------------------------------------ -------------------
 *                               2011-03-12	Jean-François Gauthier	 Création de la procédure	
 * 
 ****************************************************************************************************/
CREATE PROCEDURE [dbo].[psSECU_ObtenirListeDroitUtilisateur] 
(	
	@iID_Utilisateur VARCHAR(255)
)
AS
	BEGIN
		DECLARE 
			@iRetour			INT
			,@iErrSeverity		INT
			,@iErrState			INT
			,@vcErrmsg			VARCHAR(1024)
			,@iCodeErreur		INT		
		
		BEGIN TRY
			SELECT 
				R.RightID
				,R.RightTypeID
				,R.RightCode
			FROM 
				dbo.Mo_User U,
				dbo.Mo_Right R
			WHERE 
				U.UserID = @iID_Utilisateur 
				AND (1 = ISNULL((	SELECT	Granted
									FROM	dbo.Mo_UserRight UR
									WHERE	UR.UserID = U.UserID AND
											UR.RightID = R.RightID),0)
				OR
				   EXISTS(SELECT *
						  FROM dbo.Mo_UserGroupDtl UGD
							   INNER JOIN dbo.Mo_UserGroupRight UGR 
									ON UGR.UserGroupID = UGD.UserGroupID AND UGR.RightID = R.RightID
						  WHERE UGD.UserID = U.UserID AND
								(1 = ISNULL((SELECT Granted
											FROM dbo.Mo_UserRight UR
											WHERE 
											UR.UserID = U.UserID AND
											UR.RightID = R.RightID),1))))

			SET @iRetour = 1
		END TRY
		BEGIN CATCH
				SELECT
					@vcErrmsg			= REPLACE(ERROR_MESSAGE(),'%',' ')
					,@iErrState			= ERROR_STATE()
					,@iErrSeverity		= ERROR_SEVERITY()
					,@iCodeErreur		= ERROR_NUMBER()
					,@iRetour			= -1

				RAISERROR	(@vcErrmsg, @iErrSeverity, @iErrState) WITH LOG
		END CATCH

		RETURN @iRetour
	END
