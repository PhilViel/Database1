/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psIQEE_ImporterTraiterAnnulations
Nom du service		: Traiter les annulations/reprises pour l'importation
But 				: Traiter les annulations/reprises suite aux réponses de RQ.  Elle change le statut des
					  annulations/reprises, recrée les demandes d'annulation/reprise non actualisé et change
					  certain statut des transactions en fonction des résultats aux annulations/reprises.
Facette				: IQÉÉ

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						vcCode_Type_Fichier			Code du type de fichier en cours d'importation.

Exemple d’appel		:	Cette procédure doit uniquement être appelé du service "psIQEE_ImporterFichierReponses".

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O

Historique des modifications:
	Date		Programmeur				Description								
	----------  --------------------    -----------------------------------------
	2011-05-06	Éric Deshaies			Création du service	
	2013-09-11	Stéphane Barbeau    	Désactivation du traitement des A/R 0$ ('A0A', 'A0C', 'A0I', 'A0E')					
    2018-06-06  Steeve Picard           Modificiation de la gestion des retours d'erreur par RQ
****************************************************************************************************/
CREATE PROCEDURE dbo.psIQEE_ImporterTraiterAnnulations 
(
	@vcCode_Type_Fichier VARCHAR(3)
)
AS
BEGIN
	-- Déclarations des variables locales
	DECLARE @iID_Statut_Annulation INT,
			@iID_Utilisateur_Systeme INT


	----------------------------------------------
	-- Changer le statut des demandes d'annulation
	----------------------------------------------

	INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
	VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_ImporterTraiterAnnulations  - '+
			'Changer le statut des demandes d''annulation.')	    

	-- Mettre à jour le statut des demandes d'annulation si les transactions d'annulation, de reprise à 0$ et de la nouvelle transaction
	-- sont complétées
	
	
	-- 2013-09-11 SB: Désactivation 
	--IF @vcCode_Type_Fichier IN ('PRO','NOU')
	--	BEGIN
	--		SELECT @iID_Statut_Annulation = SA.iID_Statut_Annulation
	--		FROM tblIQEE_StatutsAnnulation SA
	--		WHERE SA.vcCode_Statut = 'A0C'

	--		UPDATE tblIQEE_Annulations
	--		SET iID_Statut_Annulation = @iID_Statut_Annulation
	--		FROM tblIQEE_Annulations A
	--			 -- Rechercher le type d'enregistrement
	--			 JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = A.tiID_Type_Enregistrement
	--			 -- Uniquement les demandes qui ont le statut "Annulation/reprise à 0$/nouvelle transaction créées - en attente de RQ"
	--			 JOIN tblIQEE_StatutsAnnulation SA ON SA.iID_Statut_Annulation = A.iID_Statut_Annulation
	--											  AND SA.vcCode_Statut = 'A0A'
	--	-- TODO: Faire la même chose pour les autres types d'enregistrement
	--			 -- Rechercher la transaction d'annulation
	--			 LEFT JOIN tblIQEE_Demandes DA ON DA.iID_Demande_IQEE = A.iID_Enregistrement_Annulation
	--			 -- Rechercher la transaction de reprise
	--			 LEFT JOIN tblIQEE_Demandes DR ON DR.iID_Demande_IQEE = A.iID_Enregistrement_Reprise
	--			 -- Rechercher la transaction de reprise originale
	--			 LEFT JOIN tblIQEE_Demandes DO ON DO.iID_Demande_IQEE = A.iID_Enregistrement_Reprise_Originale
	--			   -- les 3 transactions sont répondues
	--	-- TODO: Faire la même chose pour les autres types d'enregistrement
	--		WHERE (TE.cCode_Type_Enregistrement = '02' AND DA.cStatut_Reponse = 'R' AND DR.cStatut_Reponse = 'T' AND DO.cStatut_Reponse = 'R')
	--	END

	-- Mettre à jour le statut des demandes d'annulation si les transactions d'annulation et de reprise de la nouvelle transaction
	-- sont complétées
	IF @vcCode_Type_Fichier = 'NOU'
		BEGIN
			SELECT @iID_Statut_Annulation = SA.iID_Statut_Annulation
			FROM tblIQEE_StatutsAnnulation SA
			WHERE SA.vcCode_Statut = 'ARC'

			UPDATE tblIQEE_Annulations
			SET iID_Statut_Annulation = @iID_Statut_Annulation
			FROM tblIQEE_Annulations A
				 -- Rechercher le type d'enregistrement
				 JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = A.tiID_Type_Enregistrement
				 -- Uniquement les demandes qui ont le statut "Annulation/reprise créées - en attente de RQ"
				 JOIN tblIQEE_StatutsAnnulation SA ON SA.iID_Statut_Annulation = A.iID_Statut_Annulation
												  AND SA.vcCode_Statut = 'ARA'
		-- TODO: Faire la même chose pour les autres types d'enregistrement
				 -- Rechercher la transaction d'annulation
				 LEFT JOIN tblIQEE_Demandes DA ON DA.iID_Demande_IQEE = A.iID_Enregistrement_Annulation
				 -- Rechercher la transaction de reprise
				 LEFT JOIN tblIQEE_Demandes DR ON DR.iID_Demande_IQEE = A.iID_Enregistrement_Reprise
				   -- les 2 transactions sont répondues
		-- TODO: Faire la même chose pour les autres types d'enregistrement
			WHERE (TE.cCode_Type_Enregistrement = '02' AND DA.cStatut_Reponse = 'R' AND DR.cStatut_Reponse = 'R')
		END

	-- Mettre à jour le statut des demandes d'annulation si les transactions d'annulation et de reprise sont toutes les deux en erreur
	IF @vcCode_Type_Fichier = 'ERR'
		BEGIN
			SELECT @iID_Statut_Annulation = SA.iID_Statut_Annulation
			FROM tblIQEE_StatutsAnnulation SA
			WHERE SA.vcCode_Statut = 'ARE'

			UPDATE tblIQEE_Annulations
			SET iID_Statut_Annulation = @iID_Statut_Annulation
			FROM tblIQEE_Annulations A
				 -- Rechercher le type d'enregistrement
				 JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = A.tiID_Type_Enregistrement
				 -- Uniquement les demandes qui ont le statut "Annulation/reprise créées - en attente de RQ"
				 JOIN tblIQEE_StatutsAnnulation SA ON SA.iID_Statut_Annulation = A.iID_Statut_Annulation
												  AND SA.vcCode_Statut = 'ARA'
		-- TODO: Faire la même chose pour les autres types d'enregistrement
				 -- Rechercher la transaction d'annulation
				 LEFT JOIN tblIQEE_Demandes DA ON DA.iID_Demande_IQEE = A.iID_Enregistrement_Annulation
				 -- Rechercher la transaction de reprise
				 LEFT JOIN tblIQEE_Demandes DR ON DR.iID_Demande_IQEE = A.iID_Enregistrement_Reprise
				   -- les 2 transactions sont en erreur
		-- TODO: Faire la même chose pour les autres types d'enregistrement
			WHERE (TE.cCode_Type_Enregistrement = '02' AND DA.cStatut_Reponse = 'E' AND DR.cStatut_Reponse = 'E')

	
	-- 2013-09-11 SB: Désactivation 
			-- Mettre à jour le statut des demandes d'annulation si les transactions d'annulation, de reprise et de nouvelle transaction
			-- sont toutes les trois en erreur
		--	SELECT @iID_Statut_Annulation = SA.iID_Statut_Annulation
		--	FROM tblIQEE_StatutsAnnulation SA
		--	WHERE SA.vcCode_Statut = 'A0E'

		--	UPDATE tblIQEE_Annulations
		--	SET iID_Statut_Annulation = @iID_Statut_Annulation
		--	FROM tblIQEE_Annulations A
		--		 -- Rechercher le type d'enregistrement
		--		 JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = A.tiID_Type_Enregistrement
		--		 -- Uniquement les demandes qui ont le statut "Annulation/reprise à 0$/nouvelle transaction créées - en attente de RQ"
		--		 JOIN tblIQEE_StatutsAnnulation SA ON SA.iID_Statut_Annulation = A.iID_Statut_Annulation
		--										  AND SA.vcCode_Statut = 'A0A'
		---- TODO: Faire la même chose pour les autres types d'enregistrement
		--		 -- Rechercher la transaction d'annulation
		--		 LEFT JOIN tblIQEE_Demandes DA ON DA.iID_Demande_IQEE = A.iID_Enregistrement_Annulation
		--		 -- Rechercher la transaction de reprise
		--		 LEFT JOIN tblIQEE_Demandes DR ON DR.iID_Demande_IQEE = A.iID_Enregistrement_Reprise
		--		 -- Rechercher la transaction de reprise
		--		 LEFT JOIN tblIQEE_Demandes DO ON DO.iID_Demande_IQEE = A.iID_Enregistrement_Reprise_Originale
		--		   -- les 3 transactions sont en erreur
		---- TODO: Faire la même chose pour les autres types d'enregistrement
		--	WHERE (TE.cCode_Type_Enregistrement = '02' AND DA.cStatut_Reponse = 'E' AND DR.cStatut_Reponse = 'E' AND DO.cStatut_Reponse = 'E')
	END

	-- Mettre à jour le statut des demandes d'annulation si les transactions d'annulation, de reprise à 0$ de la nouvelle transaction
	-- sont complétées mais que la nouvelle transaction originale est en erreur
	
	-- 2013-09-11 SB: Désactivation 
	--IF @vcCode_Type_Fichier IN ('ERR','NOU')
	--	BEGIN
	--		SELECT @iID_Statut_Annulation = SA.iID_Statut_Annulation
	--		FROM tblIQEE_StatutsAnnulation SA
	--		WHERE SA.vcCode_Statut = 'A0I'

	--		UPDATE tblIQEE_Annulations
	--		SET iID_Statut_Annulation = @iID_Statut_Annulation
	--		FROM tblIQEE_Annulations A
	--			 -- Rechercher le type d'enregistrement
	--			 JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = A.tiID_Type_Enregistrement
	--			 -- Uniquement les demandes qui ont le statut "Annulation/reprise à 0$/nouvelle transaction créées - en attente de RQ"
	--			 JOIN tblIQEE_StatutsAnnulation SA ON SA.iID_Statut_Annulation = A.iID_Statut_Annulation
	--											  AND SA.vcCode_Statut = 'A0A'
	--	-- TODO: Faire la même chose pour les autres types d'enregistrement
	--			 -- Rechercher la transaction d'annulation
	--			 LEFT JOIN tblIQEE_Demandes DA ON DA.iID_Demande_IQEE = A.iID_Enregistrement_Annulation
	--			 -- Rechercher la transaction de reprise
	--			 LEFT JOIN tblIQEE_Demandes DR ON DR.iID_Demande_IQEE = A.iID_Enregistrement_Reprise
	--			 -- Rechercher la transaction de reprise originale
	--			 LEFT JOIN tblIQEE_Demandes DO ON DO.iID_Demande_IQEE = A.iID_Enregistrement_Reprise_Originale
	--			   -- les 3 transactions sont répondues
	--	-- TODO: Faire la même chose pour les autres types d'enregistrement
	--		WHERE (TE.cCode_Type_Enregistrement = '02' AND DA.cStatut_Reponse = 'R' AND DR.cStatut_Reponse = 'T' AND DO.cStatut_Reponse = 'E')
	--	END


	------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- Modifier le statut de la transaction de reprise à 0$ pour passer de "T" à "R" lorsque les transactions d'annulation, de reprise à 0$ de la nouvelle transaction
	-- sont complétées mais que la nouvelle transaction originale est en erreur afin que la transaction de reprise à 0$ devienne la transaction en vigueur en vue de
	-- la prochaine annulation/reprise.
	------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	-- 2013-09-11 SB: Désactivation 
	--IF @vcCode_Type_Fichier IN ('ERR','NOU')
	--	BEGIN
	--		INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
	--		VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_ImporterTraiterAnnulations  - '+
	--				'Remettre le statut "R" aux transactions d''origines lorsque l''annulation/reprise est en erreur.')

	--	-- TODO: Faire la même chose pour les autres types d'enregistrement
	--		UPDATE D
	--		SET cStatut_Reponse = 'R'
	--		FROM tblIQEE_Annulations A
	--			 JOIN tblIQEE_StatutsAnnulation SA ON SA.iID_Statut_Annulation = A.iID_Statut_Annulation
	--											  AND SA.vcCode_Statut = 'A0I'
	--			 JOIN tblIQEE_Demandes D ON D.iID_Demande_IQEE = A.iID_Enregistrement_Reprise
	--									AND D.cStatut_Reponse = 'T'
	--			 JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE
	--		-- Il n'y a pas de transaction subséquente à l'annulation/reprise
	--		WHERE NOT EXISTS(SELECT *
	--						 FROM tblIQEE_Demandes D2
	--							  JOIN tblIQEE_Fichiers F2 ON F2.iID_Fichier_IQEE = D2.iID_Fichier_IQEE
	--													  AND F2.siAnnee_Fiscale = F.siAnnee_Fiscale
	--													  AND F2.bFichier_Test = 0
	--													  AND F2.dtDate_Creation > F.dtDate_Creation
	--						 WHERE D2.iID_Convention = D.iID_Convention
	--						   AND D2.tiCode_Version IN (0,2))
	--	END


	------------------------------------------------------------------------------------------------
	-- Remettre le statut "R" aux transactions d'origines lorsque l'annulation/reprise est en erreur
	------------------------------------------------------------------------------------------------
	IF @vcCode_Type_Fichier = 'ERR'
		BEGIN
			INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
			VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_ImporterTraiterAnnulations  - '+
					'Remettre le statut "R" aux transactions d''origines lorsque l''annulation/reprise est en erreur.')

			UPDATE D2
			SET cStatut_Reponse = 'R'
			-- Rechercher les transactions d'annulation en erreur...
			FROM tblIQEE_Demandes D
				 -- dans les transactions d'origines.
				 JOIN #tblIQEE_Fichiers_Logiques FL ON FL.iID_Lien_Fichier_IQEE_Demande = D.iID_Fichier_IQEE
				 -- Rechercher les demandes d'annulation en attente à l'origine de la transaction d'annulation...
				 JOIN tblIQEE_Annulations A ON A.iID_Enregistrement_Annulation = D.iID_Demande_IQEE
				 -- pour les enregistrements de demande
				 JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = A.tiID_Type_Enregistrement
													 AND TE.cCode_Type_Enregistrement = '02'
				 -- si toutes les transactions de l'annulation/reprise (annulation,reprise,reprise originale), sont en erreur...
				 JOIN tblIQEE_StatutsAnnulation SA ON SA.iID_Statut_Annulation = A.iID_Statut_Annulation
												  AND SA.vcCode_Statut = 'ARE' ---- IN ('A0E','ARE')  2013-09-11 SB: Désactivation  
				 -- Mettre à jour les demandes originales
				 JOIN tblIQEE_Demandes D2 ON D2.iID_Demande_IQEE = A.iID_Enregistrement_Demande_Annulation
										 AND D2.cStatut_Reponse = 'D'
										 AND NOT EXISTS(SELECT *
														FROM tblIQEE_Annulations A2
															 JOIN tblIQEE_StatutsAnnulation SA2 ON SA2.iID_Statut_Annulation = A2.iID_Statut_Annulation
																							   AND SA2.vcCode_Statut = 'ARA'-- IN ('ARA','A0A') 2013-09-11 SB: Désactivation  
														WHERE A2.iID_Enregistrement_Demande_Annulation = D2.iID_Demande_IQEE)
			WHERE D.tiCode_Version = 1
			  AND D.cStatut_Reponse = 'E'
			  AND EXISTS(SELECT *
						 FROM tblIQEE_Erreurs E
							  JOIN #tblIQEE_Fichiers_Logiques FL ON FL.iID_Fichier_IQEE = E.iID_Fichier_IQEE
						 WHERE E.iID_Enregistrement = D.iID_Demande_IQEE
						   AND E.tiID_Type_Enregistrement = TE.tiID_Type_Enregistrement)


		-- TODO: Faire la même chose pour les autres types d'enregistrement - A confirmer avec le graphique "Statuts et versions des transactions"
		--       S'il y a une erreur sur des transactions de reprise (type 06) et que la transaction d'annulation est correcte (type 06),
		--		 mettre la réponse "R" sur la transaction d'annulation et "T" sur la transaction à l'origine de l'annulation
		END


-- TODO: Si on permet le passage d'une transaction en erreur "E" vers une transaction en réponse "R" parce que RQ a changé d'avis
--		 sur la qualité de notre transaction, mettre le statut des erreurs RQ à « Terminé » s’il y a eu une réponse après avoir
--		 eu une erreur RQ par erreur.  Présentement, on ne laisse pas passer ça en attendant de voir si ça va se reproduire. Si on
--       met à jour le statut des erreurs, il faut aussi mettre à jour le statut des fichiers d'erreurs avec psIQEE_MettreAJourStatutRapportsErreurs
--	IF @vcCode_Type_Fichier IN ('PRO','NOU')
--		BEGIN
--		END


	----------------------------------------------------
	-- Déterminer l'identifiant de l'utilisateur système
	----------------------------------------------------
	SELECT TOP 1 @iID_Utilisateur_Systeme = iID_Utilisateur_Systeme
	FROM Un_Def


	-----------------------------------------------------------------------------------------------------------------
	-- Réactiver (recréer) les demandes d'annulation manuelles qui étaient à l'origine d'annulation/reprise en erreur
	-----------------------------------------------------------------------------------------------------------------
	IF @vcCode_Type_Fichier = 'ERR'
		BEGIN
			INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
			VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_ImporterTraiterAnnulations  - '+
					'Réactiver (recréer) les demandes d''annulation manuelles qui étaient à l''origine d''annulation/reprise en erreur.')

			-- Déterminer l'identifiant du statut d'annulation "Demande d'annulation manuelle créée - en attente de la création
			-- d'un fichier de transactions"
			SELECT @iID_Statut_Annulation = SA.iID_Statut_Annulation
			FROM tblIQEE_StatutsAnnulation SA
			WHERE SA.vcCode_Statut = 'MAN'

			-- Recréer les demandes d'annulation manuelles
			INSERT INTO dbo.tblIQEE_Annulations
					   (tiID_Type_Enregistrement
					   ,iID_Enregistrement_Demande_Annulation
					   ,dtDate_Demande_Annulation
					   ,iID_Utilisateur_Demande
					   ,iID_Type_Annulation
					   ,iID_Raison_Annulation
					   ,tCommentaires
					   ,iID_Statut_Annulation)
			SELECT	A.tiID_Type_Enregistrement,
					A.iID_Enregistrement_Demande_Annulation,
					GETDATE(),
					@iID_Utilisateur_Systeme,
					A.iID_Type_Annulation,
					A.iID_Raison_Annulation,
					A.tCommentaires,
					@iID_Statut_Annulation
			FROM tblIQEE_Annulations A
				 -- Transactions de demande d'IQÉÉ seulement
				 JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = A.tiID_Type_Enregistrement
													AND TE.cCode_Type_Enregistrement = '02'
				 -- Uniquement les demandes qui ont un statut qui indique que l'annulation/reprise n'a pas fonctionnée
				 JOIN tblIQEE_StatutsAnnulation SA ON SA.iID_Statut_Annulation = A.iID_Statut_Annulation
												  AND SA.vcCode_Statut = 'ARE' --IN ('ARE','A0E') 2013-09-11 SB: Désactivation
				 -- Uniquement les demandes manuelles
				 JOIN tblIQEE_TypesAnnulation TA ON TA.iID_Type_Annulation = A.iID_Type_Annulation
												AND TA.vcCode_Type = 'MAN'
				 -- Rechercher la transaction d'annulation...
				 JOIN tblIQEE_Demandes DA ON DA.iID_Demande_IQEE = A.iID_Enregistrement_Annulation
				 -- dans les transactions d'origines de l'importation en cours
				 JOIN #tblIQEE_Fichiers_Logiques FL1 ON FL1.iID_Lien_Fichier_IQEE_Demande = DA.iID_Fichier_IQEE
				 -- Rechercher la transaction de reprise...
				 JOIN tblIQEE_Demandes DR ON DR.iID_Demande_IQEE = A.iID_Enregistrement_Reprise
				 -- dans les transactions d'origines de l'importation en cours
				 JOIN #tblIQEE_Fichiers_Logiques FL2 ON FL2.iID_Lien_Fichier_IQEE_Demande = DR.iID_Fichier_IQEE
			WHERE NOT EXISTS(SELECT *
							 FROM tblIQEE_Annulations A2
								  -- Uniquement les demandes manuelles
								  JOIN tblIQEE_TypesAnnulation TA2 ON TA2.iID_Type_Annulation = A2.iID_Type_Annulation
																  AND TA2.vcCode_Type = 'MAN'
							 WHERE A2.tiID_Type_Enregistrement = A.tiID_Type_Enregistrement
							   AND A2.iID_Enregistrement_Demande_Annulation = A.iID_Enregistrement_Demande_Annulation
							   AND A2.iID_Type_Annulation = A.iID_Type_Annulation
							   AND A2.iID_Raison_Annulation = A.iID_Raison_Annulation
							   AND A2.iID_Statut_Annulation = @iID_Statut_Annulation)
				-- L'une des erreurs de l'annulation ou de la reprise doit avoir été faite dans l'importation en cours
			  AND (EXISTS(SELECT *
						  FROM tblIQEE_Erreurs E
							   JOIN #tblIQEE_Fichiers_Logiques FL ON FL.iID_Fichier_IQEE = E.iID_Fichier_IQEE
						  WHERE E.iID_Enregistrement = DA.iID_Fichier_IQEE
						    AND E.tiID_Type_Enregistrement = TE.tiID_Type_Enregistrement)
				   OR
				   EXISTS(SELECT *
						  FROM tblIQEE_Erreurs E
							   JOIN #tblIQEE_Fichiers_Logiques FL ON FL.iID_Fichier_IQEE = E.iID_Fichier_IQEE
						  WHERE E.iID_Enregistrement = DR.iID_Fichier_IQEE
						    AND E.tiID_Type_Enregistrement = TE.tiID_Type_Enregistrement))

		-- TODO: Appliquer aux autres types d'enregistrement
		END


	----------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- Réactiver (recréer) les demandes d'annulation manuelles qui étaient à l'origine d'annulation/reprise à 0$ pour laquelle l’annulation/reprise est complété
	-- mais que la transaction originale est en erreur.  La nouvelle demande d’annulation/reprise porte sur la transaction de reprise à 0$ au lieu de la transaction
	-- originale avant l’annulation/reprise à 0$ puisse que ces la transaction de reprise à 0$ qui est la transaction en vigueur.
	----------------------------------------------------------------------------------------------------------------------------------------------------------------

		-- Désactivation 2013-09-11 SB
	--IF @vcCode_Type_Fichier IN ('ERR','NOU')
	--	BEGIN
	--		INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
	--		VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_ImporterTraiterAnnulations  - '+
	--				'Réactiver (recréer) les demandes d''annulation manuelles pour les annulations/reprises complétées mais les transactions originale en erreur.')

	--		-- Déterminer l'identifiant du statut d'annulation "Demande d'annulation manuelle créée - en attente de la création
	--		-- d'un fichier de transactions"
	--		SELECT @iID_Statut_Annulation = SA.iID_Statut_Annulation
	--		FROM tblIQEE_StatutsAnnulation SA
	--		WHERE SA.vcCode_Statut = 'MAN'

	--		-- Recréer les demandes d'annulation manuelles
	--	-- TODO: Code à retirées après les tests
	--		INSERT INTO [dbo].[tblIQEE_Annulations]
	--				   ([tiID_Type_Enregistrement]
	--				   ,[iID_Enregistrement_Demande_Annulation]
	--				   ,[dtDate_Demande_Annulation]
	--				   ,[iID_Utilisateur_Demande]
	--				   ,[iID_Type_Annulation]
	--				   ,[iID_Raison_Annulation]
	--				   ,[tCommentaires]
	--				   ,[iID_Statut_Annulation])
	--		SELECT	A.tiID_Type_Enregistrement,
	--				A.iID_Enregistrement_Reprise,
	--				GETDATE(),
	--				@iID_Utilisateur_Systeme,
	--				A.iID_Type_Annulation,
	--				A.iID_Raison_Annulation,
	--				A.tCommentaires,
	--				@iID_Statut_Annulation
	--		FROM tblIQEE_Annulations A
	--			 -- Transactions de demande d'IQÉÉ seulement
	--			 JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = A.tiID_Type_Enregistrement
	--												AND TE.cCode_Type_Enregistrement = '02'
	--			 -- Uniquement les demandes qui ont un statut qui indique que l'annulation/reprise n'a pas fonctionnée
	--			 JOIN tblIQEE_StatutsAnnulation SA ON SA.iID_Statut_Annulation = A.iID_Statut_Annulation
	--											  AND SA.vcCode_Statut = 'A0I'
	--			 -- Uniquement les demandes manuelles
	--			 JOIN tblIQEE_TypesAnnulation TA ON TA.iID_Type_Annulation = A.iID_Type_Annulation
	--											AND TA.vcCode_Type = 'MAN'
	--			 -- Rechercher la transaction d'annulation...
	--			 LEFT JOIN tblIQEE_Demandes DA ON DA.iID_Demande_IQEE = A.iID_Enregistrement_Annulation
	--			 -- dans les transactions d'origines de l'importation en cours
	--			 LEFT JOIN #tblIQEE_Fichiers_Logiques FL1 ON FL1.iID_Lien_Fichier_IQEE_Demande = DA.iID_Fichier_IQEE
	--			 -- Rechercher la transaction de reprise...
	--			 LEFT JOIN tblIQEE_Demandes DR ON DR.iID_Demande_IQEE = A.iID_Enregistrement_Reprise
	--			 -- dans les transactions d'origines de l'importation en cours
	--			 LEFT JOIN #tblIQEE_Fichiers_Logiques FL2 ON FL2.iID_Lien_Fichier_IQEE_Demande = DR.iID_Fichier_IQEE
	--			 -- Rechercher la transaction de reprise...
	--			 LEFT JOIN tblIQEE_Demandes DR0 ON DR0.iID_Demande_IQEE = A.iID_Enregistrement_Reprise_Originale
	--			 -- dans les transactions d'origines de l'importation en cours
	--			 LEFT JOIN #tblIQEE_Fichiers_Logiques FL3 ON FL3.iID_Lien_Fichier_IQEE_Demande = DR0.iID_Fichier_IQEE
	--		WHERE (FL1.iID_Lien_Fichier_IQEE_Demande IS NOT NULL OR FL2.iID_Lien_Fichier_IQEE_Demande IS NOT NULL OR FL3.iID_Lien_Fichier_IQEE_Demande IS NOT NULL)
	--		  AND NOT EXISTS(SELECT *
	--						 FROM tblIQEE_Annulations A2
	--							  -- Uniquement les demandes manuelles
	--							  JOIN tblIQEE_TypesAnnulation TA2 ON TA2.iID_Type_Annulation = A2.iID_Type_Annulation
	--															  AND TA2.vcCode_Type = 'MAN'
	--						 WHERE A2.tiID_Type_Enregistrement = A.tiID_Type_Enregistrement
	--						   AND A2.iID_Enregistrement_Demande_Annulation = A.iID_Enregistrement_Reprise
	--						   AND A2.iID_Type_Annulation = A.iID_Type_Annulation
	--						   AND A2.iID_Raison_Annulation = A.iID_Raison_Annulation
	--						   AND A2.iID_Statut_Annulation = @iID_Statut_Annulation)

	--		INSERT INTO [dbo].[tblIQEE_Annulations]
	--				   ([tiID_Type_Enregistrement]
	--				   ,[iID_Enregistrement_Demande_Annulation]
	--				   ,[dtDate_Demande_Annulation]
	--				   ,[iID_Utilisateur_Demande]
	--				   ,[iID_Type_Annulation]
	--				   ,[iID_Raison_Annulation]
	--				   ,[tCommentaires]
	--				   ,[iID_Statut_Annulation])
	--		SELECT	A.tiID_Type_Enregistrement,
	--				A.iID_Enregistrement_Reprise,
	--				GETDATE(),
	--				@iID_Utilisateur_Systeme,
	--				A.iID_Type_Annulation,
	--				A.iID_Raison_Annulation,
	--				A.tCommentaires,
	--				@iID_Statut_Annulation
	--		FROM tblIQEE_Annulations A
	--			 -- Transactions de demande d'IQÉÉ seulement
	--			 JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = A.tiID_Type_Enregistrement
	--												AND TE.cCode_Type_Enregistrement = '02'
	--			 -- Uniquement les demandes qui ont un statut qui indique que l'annulation/reprise n'a pas fonctionnée
	--			 JOIN tblIQEE_StatutsAnnulation SA ON SA.iID_Statut_Annulation = A.iID_Statut_Annulation
	--											  AND SA.vcCode_Statut = 'A0I'
	--			 -- Uniquement les demandes manuelles
	--			 JOIN tblIQEE_TypesAnnulation TA ON TA.iID_Type_Annulation = A.iID_Type_Annulation
	--											AND TA.vcCode_Type = 'MAN'
		
		
		
	--	---- TODO: Conditions à retirées après les tests
	--	--		 -- Rechercher la transaction d'annulation...
	--	--		 LEFT JOIN tblIQEE_Demandes DA ON DA.iID_Demande_IQEE = A.iID_Enregistrement_Annulation
	--	--		 -- dans les transactions d'origines de l'importation en cours
	--	--		 LEFT JOIN #tblIQEE_Fichiers_Logiques FL1 ON FL1.iID_Lien_Fichier_IQEE_Demande = DA.iID_Fichier_IQEE
	--			 -- Rechercher la transaction de reprise...
	--			 JOIN tblIQEE_Demandes DR ON DR.iID_Demande_IQEE = A.iID_Enregistrement_Reprise
	--			 JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = DR.iID_Fichier_IQEE
	--	--		 -- dans les transactions d'origines de l'importation en cours
	--	--		 LEFT JOIN #tblIQEE_Fichiers_Logiques FL2 ON FL2.iID_Lien_Fichier_IQEE_Demande = DR.iID_Fichier_IQEE
	--	--		 -- Rechercher la transaction de reprise...
	--	--		 LEFT JOIN tblIQEE_Demandes DR0 ON DR0.iID_Demande_IQEE = A.iID_Enregistrement_Reprise_Originale
	--	--		 -- dans les transactions d'origines de l'importation en cours
	--	--		 LEFT JOIN #tblIQEE_Fichiers_Logiques FL3 ON FL3.iID_Lien_Fichier_IQEE_Demande = DR0.iID_Fichier_IQEE
	--		WHERE --(FL1.iID_Lien_Fichier_IQEE_Demande IS NOT NULL OR FL2.iID_Lien_Fichier_IQEE_Demande IS NOT NULL OR FL3.iID_Lien_Fichier_IQEE_Demande IS NOT NULL)
	--			  -- La demande d'annulation/reprise n'existe pas déjà
	--			  NOT EXISTS(SELECT *
	--						 FROM tblIQEE_Annulations A2
	--							  -- Uniquement les demandes manuelles
	--							  JOIN tblIQEE_TypesAnnulation TA2 ON TA2.iID_Type_Annulation = A2.iID_Type_Annulation
	--															  AND TA2.vcCode_Type = 'MAN'
	--						 WHERE A2.tiID_Type_Enregistrement = A.tiID_Type_Enregistrement
	--						   AND A2.iID_Enregistrement_Demande_Annulation = A.iID_Enregistrement_Reprise
	--						   AND A2.iID_Type_Annulation = A.iID_Type_Annulation
	--						   AND A2.iID_Raison_Annulation = A.iID_Raison_Annulation
	--						   AND A2.iID_Statut_Annulation = @iID_Statut_Annulation)
	--		  -- Il n'y a pas de transaction subséquente à l'annulation/reprise
	--		  AND NOT EXISTS(SELECT *
	--						 FROM tblIQEE_Demandes D2
	--							  JOIN tblIQEE_Fichiers F2 ON F2.iID_Fichier_IQEE = D2.iID_Fichier_IQEE
	--													  AND F2.siAnnee_Fiscale = F.siAnnee_Fiscale
	--													  AND F2.bFichier_Test = 0
	--													  AND F2.dtDate_Creation > F.dtDate_Creation
	--						 WHERE D2.iID_Convention = DR.iID_Convention
	--						   AND D2.tiCode_Version IN (0,2))

	--	-- TODO: Appliquer aux autres types d'enregistrement
		

	--	END
END
