/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc

Code de service		:		psCONV_VerifierBourseVersee
Nom du service		:		Annuler une opération FRS.
But					:		Annuler une opération FRS.
							dans les tables d'uniAccés.
Facette				:		CONV
Reférence			:		UniAccés-Noyau-OPER

Parametres d'entrée :	Parametres					Description
						-----------------------------------------------------------------------------------------------------
						@iID_Convention			Identifiant de la convention
Exemple d'appel:
						
						

Parametres de sortie : Table						Champs								Description
					   -----------------			---------------------------			--------------------------
													@iCode_Retour						C'est un code de retour qui indique si le traitement :
																						 s'est terminée avec succès et si les frais sont couverts
																						@iCode_Retour < 0  : Echec
																						@iCode_Retour = 0  : traitement s'est bien deroulé
			
Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2011-03-25					Frédérick Thibault						Création de la procédure
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_VerifierBourseVersee]
	( 
	@iID_Convention	INTEGER
	) 
AS
BEGIN
	DECLARE @iCodeRetour INTEGER

	SELECT 1
	FROM Un_CESP CE	
	JOIN Un_Oper OP ON OP.OperID = CE.OperId
	WHERE OP.OperTypeID = 'PAE'
	AND   CE.ConventionID = @iID_Convention

END
