/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fnPCEE_CalculerMontant400OperationFCB
Nom du service		: Retourne le montant à décalrer au PCEE pour un FCB
But 				: Retourne le montant à décalrer au PCEE pour un FCB
Facette				: PCEE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						iID_Operation				Identifiant unique de l'opération FCB.
												

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						N/A							N/A								Montant à déclarer au PCEE pour le
																					l'opération FCB. 
	
Exemple d'appel : SELECT dbo.fnPCEE_CalculerMontant400OperationFCB(20126344)

Historique des modifications:
		Date			Programmeur					Description						Référence
		------------	-------------------------	---------------------------  	------------
		2012-12-03		Pierre-Luc Simard			Création du service
		
****************************************************************************************************/
CREATE FUNCTION [dbo].[fnPCEE_CalculerMontant400OperationFCB] (@iID_Operation INT)
RETURNS MONEY
AS 
    BEGIN
		-- Déclaration des variables
        DECLARE @mMontant_FCB MONEY ;
        
        DECLARE @FCB TABLE (
			UnitID INTEGER,
			FCBOperID INTEGER,
			FCBDate DATETIME,
			FCBMontant MONEY)

		-- Liste des FCB à envoyer ou envoyés au PCEE
		INSERT INTO @FCB
		SELECT 
			CT.UnitID,
			O.OperID,
			O.OperDate,
			FCBMontant = CT.Cotisation + CT.Fee
		FROM Un_Oper O 
		JOIN Un_Cotisation CT ON CT.OperID = O.OperID
		WHERE O.OperID = @iID_Operation
			AND O.OperTypeID = 'FCB'        
        		        
        -- Calcul du montant à décalrer au PCEE pour le FCB
		SELECT 
			@mMontant_FCB = SUM(CT.Cotisation + CT.Fee)
		FROM @FCB FCB --@iID_Operation
		JOIN Un_Cotisation CT ON CT.UnitID = FCB.UnitID
		JOIN Un_Oper O ON O.OperID = CT.OperID
		LEFT JOIN Mo_BankReturnLink BL ON BL.BankReturnCodeID = O.OperID
		LEFT JOIN Un_Oper OS ON OS.OperID = BL.BankReturnSourceCodeID
		WHERE ((O.OperTypeID = 'NSF' AND O.OperDate >= FCB.FCBDate AND OS.OperDate < FCB.FCBDate) -- NSF après FCB pour cotisation antérieure au FCB
			OR (O.OperDate < FCB.FCBDate)) -- Cotisation avant le FCB
			AND NOT ((FCB.FCBDate > '2012-10-31' AND O.OperTypeID = 'TFR' AND (CT.Cotisation + CT.Fee) > 0)) -- Exclure les TFR positifs après le 2012-10-31 -- Ne pas changer cette date
		GROUP BY 
			FCB.UnitID,
			FCB.FCBOperID,
			FCB.FCBDate,
			FCB.FCBMontant
        
       RETURN ROUND(ISNULL(@mMontant_FCB, 0),2);
    END

