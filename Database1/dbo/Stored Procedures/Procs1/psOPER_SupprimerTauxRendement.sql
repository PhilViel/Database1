/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psOPER_SupprimerTauxRendement
Nom du service		: TBLOPER_RENDEMENTS 
But 				: Permet de supprimer un taux de rendement pour l'identifiant taux de rendement reçu en paramètre
Description			: Cette fonction est appelée lorsque l'utilisateur supprime un taux de rendement.

Facette				: OPER
Référence			: Noyau-OPER

Paramètres d’entrée	:	Paramètre					Obligatoire	Description
						--------------------------	-----------	-----------------------------------------------------------------
						iID_Taux_Rendement			Oui			Identifiant unique du taux de rendement à supprimer
		  			

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						N/A							iCode_Retour					0	= traitement réussi
																					-1	= erreur de traitement
Exemple d'appel : 
					DECLARE @i	INT
					EXECUTE @i = dbo.psOPER_SupprimerTauxRendement 30
					PRINT @i


Historique des modifications:
		Date			Programmeur					Description						Référence
		------------	-------------------------	---------------------------  	------------
		2009-08-06		Jean-François Gauthier		Création de la procédure		1.4.3 dans le P171U - Services du noyau de la facette OPER - Opérations
		
****************************************************************************************************/
CREATE PROCEDURE dbo.psOPER_SupprimerTauxRendement
	(
		@iID_Taux_Rendement	INT	
	)
AS
	BEGIN
		SET NOCOUNT ON
		SET XACT_ABORT ON

		-- DÉFINITION DES VARIABLES DE CONTRÔLE DE LA PROCÉDURE
		DECLARE
			@iErrno				INT
			,@iErrSeverity		INT
			,@iErrState			INT
			,@vErrmsg			VARCHAR(1024)
			,@iCode_Retour		INT

		-- DÉFINITION DES VARIABLES DE TRAITEMENT
		DECLARE
			@iID_Rendement		INT
			,@iNbTaux			INT

		BEGIN TRY
			-----------------
			BEGIN TRANSACTION
			-----------------
			
			-- RECUPÉRER LE iID_RENDEMENT ASSOCIÉ
			SELECT 
				@iID_Rendement	= tr2.iID_Rendement,
				@iNbTaux		= COUNT(*)
			FROM
				dbo.tblOPER_TauxRendement tr1
				INNER JOIN
					dbo.tblOPER_TauxRendement tr2
						ON tr1.iID_Rendement = tr2.iID_Rendement
			WHERE 
				tr1.iID_Taux_Rendement = @iID_Taux_Rendement
			GROUP BY
				tr2.iID_Rendement

			-- SUPPRESSION DANS LA TABLE TBLOPER_TAUXRENDEMENT
			DELETE 
				FROM dbo.tblOPER_TauxRendement
			WHERE 
				iID_Taux_Rendement = @iID_Taux_Rendement
			
			-- IL N'Y AVAIT QU'UN SEUL TAUX DE RENDEMENT ASSOCIÉ, ON PEUT DONC SUPPRIMER LE RENDEMENT
			IF @iNbTaux = 1	
				BEGIN
					DELETE 
						FROM dbo.tblOPER_Rendements
					WHERE
						iID_Rendement = @iID_Rendement
				END
			ELSE		-- METTRE À JOUR TBLOPER_RENDEMENTS AFIN DE RÉACTIVÉ LE TAUX DE RENDEMENT LE PLUS RÉCENT
				BEGIN
					-- VÉRIFICATION S'IL N'Y PAS DÉJÀ UN RENDEMENT ACTIF
					IF NOT EXISTS(	SELECT 1 FROM dbo.tblOPER_TauxRendement 
									WHERE iID_Rendement = @iID_Rendement AND (dtDate_Fin_Application IS NULL))
						BEGIN
							UPDATE	dbo.tblOPER_TauxRendement
							SET		dtDate_Fin_Application = NULL
							WHERE	
									iID_Rendement = @iID_Rendement
									AND
									dtDate_Fin_Application = (	SELECT MAX(t.dtDate_Fin_Application) 
																FROM dbo.tblOPER_TauxRendement t
																WHERE iID_Rendement = @iID_Rendement	)	
						END
				END
			------------------
			COMMIT TRANSACTION
			------------------
			SET @iCode_Retour = 0
		END TRY
		BEGIN CATCH
			-- RÉCUPÉRATION DES INFORMATIONS CONCERNANT L'ERREUR
			SELECT										
					@vErrmsg		= REPLACE(ERROR_MESSAGE(),'%',' '),
					@iErrState		= ERROR_STATE(),
					@iErrSeverity	= ERROR_SEVERITY(),
					@iErrno			= ERROR_NUMBER();

			-- LA TRANSACTION EST TOUJOURS ACTIVE, ON PEUT FAIRE UN ROLLBACK
			IF (XACT_STATE()) = -1	
				BEGIN
					-----------------------
					ROLLBACK TRANSACTION
					-----------------------						
				END

			-- CONCATÉNATION DU NUMÉRO D'ERREUR INTERNE À SQL SERVEUR
			SET @vErrmsg = CAST(@iErrno AS VARCHAR(6)) + ' : ' + @vErrmsg
			RAISERROR	(@vErrmsg, @iErrSeverity, @iErrState)	

			SET @iCode_Retour = -1
		END CATCH

		RETURN @iCode_Retour
	END
