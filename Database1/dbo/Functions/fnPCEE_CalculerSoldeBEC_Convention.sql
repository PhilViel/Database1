﻿
/****************************************************************************************************
Code de service		:		fnPCEE_CalculerSoldeBEC_Convention
Nom du service		:		CalculerSoldeBEC_Convention
But					:		Calculer le solde BEC d'une convention
Facette				:		PCEE
Reférence			:		Système de gestion de la relation client

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
                        iID_Convention              ID de la convention concernée par l'appel
                        dtDate_Fin                  Date de fin de la période considérée par l'appel


Exemple d'appel:
                SELECT * FROM DBO.[fnPCEE_CalculerSoldeBEC_Convention] (1234, 2011-12-19 07:52:45.930)

Parametres de sortie : Le solde SCEE

Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2012-07-24                  Dominique Pothier                       Création de la fonction
 ****************************************************************************************************/
 
CREATE FUNCTION [dbo].[fnPCEE_CalculerSoldeBEC_Convention]
					(	
	                        @iID_Convention 				INT,
							@dtDate_Fin  				DATETIME
					)
RETURNS  money
AS
BEGIN
DECLARE 
		@mMontant_Subventions money

		set @mMontant_Subventions = 0

SELECT @mMontant_Subventions = SUM(ISNULL(cesp.fCLB,0)) -- BEC
FROM dbo.Un_CESP cesp
	JOIN dbo.Un_Oper uo on uo.operid = cesp.operid
WHERE cesp.ConventionID = @iID_Convention
and uo.operdate <= @dtDate_Fin
	

RETURN ISNULL(@mMontant_Subventions,0)
END