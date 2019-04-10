/****************************************************************************************************
Code de service		:		fnPCEE_ObtenirUniteBEC
Nom du service		:		1.1.1 Obtenir l'unité qui est rattachée au BEC d'une convention
But					:		Ce service est utilisé afin de récupérer l'identifiant unique de l'unité qui est rattachée au BEC
							Lors de la demande de BEC, une cotisation à zéro est créée et celle-ci est rattachée à une unité.
Facette				:		PCEE
Reférence			:		Document psPCEE_ObtenirUnitBEC.DOCX


Parametres d'entrée :	Parametres					Description									Obligatoire
                        ----------                  ----------------							--------------                       
                        @vcConventionNo				Numéro de la convention						Oui

Exemples d'appel:
				SELECT dbo.fnPCEE_ObtenirUniteBEC('U-20060302052')	-- RETOURNE 432497
				SELECT dbo.fnPCEE_ObtenirUniteBEC('U-0')			-- RETOURNE -1

Parametres de sortie :  Table						Champs										Description
					    -----------------			---------------------------					--------------------------
						Un_Cotisation				UnitID										Identifiant de l'unité du BEC
													iID_CodeErreur								Code d'erreur

Historique des modifications :

						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-10-14					Jean-François Gauthier					Création de la fonction

N.B.

VOICI L'OPTIMISATION À FAIRE POUR CETTE REQUÊTE :

CREATE NONCLUSTERED INDEX [_dta_index_Un_CESP400_7_1672549192__K13_K8_K17_K6_K7_K4_K1] ON [dbo].[Un_CESP400] 
(
	[ConventionNo] ASC,
	[tiCESP400TypeID] ASC,
	[bCESPDemand] ASC,
	[iCESP800ID] ASC,
	[iReversedCESP400ID] ASC,
	[CotisationID] ASC,
	[iCESP400ID] ASC
)WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF)
go

CREATE STATISTICS [_dta_stat_1672549192_6_8] ON [dbo].[Un_CESP400]([iCESP800ID], [tiCESP400TypeID])
go

CREATE STATISTICS [_dta_stat_1672549192_7_8_17] ON [dbo].[Un_CESP400]([iReversedCESP400ID], [tiCESP400TypeID], [bCESPDemand])
go

CREATE STATISTICS [_dta_stat_1672549192_17_8_6_7] ON [dbo].[Un_CESP400]([bCESPDemand], [tiCESP400TypeID], [iCESP800ID], [iReversedCESP400ID])
go

CREATE STATISTICS [_dta_stat_1672549192_4_8_17_6_7] ON [dbo].[Un_CESP400]([CotisationID], [tiCESP400TypeID], [bCESPDemand], [iCESP800ID], [iReversedCESP400ID])
go

CREATE STATISTICS [_dta_stat_1672549192_1_4_8_17_6_7] ON [dbo].[Un_CESP400]([iCESP400ID], [CotisationID], [tiCESP400TypeID], [bCESPDemand], [iCESP800ID], [iReversedCESP400ID])
go

CREATE STATISTICS [_dta_stat_1672549192_1_6_7_13_8_17] ON [dbo].[Un_CESP400]([iCESP400ID], [iCESP800ID], [iReversedCESP400ID], [ConventionNo], [tiCESP400TypeID], [bCESPDemand])
go

CREATE STATISTICS [_dta_stat_1672549192_4_1_6_7_13_8_17] ON [dbo].[Un_CESP400]([CotisationID], [iCESP400ID], [iCESP800ID], [iReversedCESP400ID], [ConventionNo], [tiCESP400TypeID], [bCESPDemand])
go

CREATE NONCLUSTERED INDEX [_dta_index_Un_Cotisation_7_293016225__K1_3] ON [dbo].[Un_Cotisation] 
(
	[CotisationID] ASC
)
INCLUDE ( [UnitID]) WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF)
go

CREATE STATISTICS [_dta_stat_293016225_3_1] ON [dbo].[Un_Cotisation]([UnitID], [CotisationID])
go

						
 ****************************************************************************************************/
CREATE FUNCTION [dbo].[fnPCEE_ObtenirUniteBEC]
	(
		@vcConventionNo VARCHAR(15)
	)
RETURNS INTEGER
AS
	BEGIN
		DECLARE @iIDUnite	INT

		SELECT
			@iIDUnite = c.UnitID
		FROM
			dbo.Un_Cotisation c
			INNER JOIN dbo.Un_CESP400 ce
				ON c.CotisationID = ce.CotisationID 
			INNER JOIN (SELECT MaxID = MAX(ce2.iCESP400ID), ce2.CotisationID FROM dbo.Un_CESP400 ce2 GROUP BY ce2.CotisationID) ce3
				ON ce.iCESP400ID = ce3.MaxID AND c.CotisationID = ce3.CotisationID
		WHERE
			ce.ConventionNo			= @vcConventionNo
			AND
			ce.tiCESP400TypeID		= 24
			AND
			ce.iCESPSendFileID		IS NOT NULL
			AND
			ce.bCESPDemand			= 1
			AND
			ce.iCESP800ID			IS NULL
			AND
			ce.iReversedCESP400ID	IS NULL
			AND
			ce.CotisationID			IS NOT NULL

		IF @iIDUnite IS NULL		-- AUCUNE VALEUR N'EST RETOURNÉE
			BEGIN
				SET @iIDUnite = -1
			END
			
		RETURN @iIDUnite
	END
