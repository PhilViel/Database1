/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fnIQEE_ConventionEnAttenteRQ
Nom du service		: Convention en attente de RQ
But 				: Déterminer si une convention a au moins 1 transaction qui est en attente d'une réponse de RQ en
					  date du jour.
Facette				: IQÉÉ

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						iID_Convention				Identifiant de la convention que l'on désire savoir si elle est
													en attente ou non de RQ.
						bFichiers_Test_Comme_		Indicateur si les fichiers test doivent être tenue en compte dans
							Production				les transactions sélectionnées pour déterminer si la convention est
													en attente ou non de RQ.  Normalement ce n’est pas le cas.  Mais
													pour fins d’essais et de simulations il est possible de tenir compte
													des fichiers tests comme des fichiers de production.  S’il est absent,
													les fichiers test ne sont pas considérés.

Exemple d’appel		:	SELECT [dbo].[fnIQEE_ConventionEnAttenteRQ](300000,0)

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							bConventionEnAttenteRQ			0 = La convention n'est pas en
																						attente de RQ
																					1 = La convention est en attente
																						de RQ

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2010-09-20		Éric Deshaies						Création du service
		2012-12-04		Stéphane Barbeau					Ajustement Condition cStatut_Reponse = 'D'
****************************************************************************************************/
CREATE FUNCTION [dbo].[fnIQEE_ConventionEnAttenteRQ]
(
	@iID_Convention INT,
	@bFichiers_Test_Comme_Production BIT
)
RETURNS BIT
AS
BEGIN
	DECLARE @bConventionEnAttenteRQ BIT

	-- Confirmer la valeur des paramètres absents
	SET @iID_Convention = ISNULL(@iID_Convention,0)
	SET @bFichiers_Test_Comme_Production = ISNULL(@bFichiers_Test_Comme_Production,0)

	-- Trouver des transactions en attente d'une réponse pour la convention
	IF EXISTS(SELECT *
			  FROM tblIQEE_Demandes D
				   JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE
										  AND (@bFichiers_Test_Comme_Production = 1
											   OR F.bFichier_Test = 0)
										  AND F.bInd_Simulation = 0
			  WHERE D.iID_Convention = @iID_Convention
				AND D.cStatut_Reponse = 'A' OR ( D.cStatut_Reponse = 'D'  
												 AND EXISTS (Select * FROM tblIQEE_Demandes D1 where D1.iID_Convention = @iID_Convention AND D1.tiCode_Version = 1 AND D1.cStatut_Reponse='A') 
				                                 AND EXISTS (Select * FROM tblIQEE_Demandes D2 where D2.iID_Convention = @iID_Convention AND D2.tiCode_Version = 2 AND D2.cStatut_Reponse='A')
				                               ) 
				)
-- TODO: Ajouter les autres types d'enregistrement 03 à 06
		SET @bConventionEnAttenteRQ = 1
	ELSE
		SET @bConventionEnAttenteRQ = 0

	--  Retourner la valeur
	RETURN @bConventionEnAttenteRQ
END


