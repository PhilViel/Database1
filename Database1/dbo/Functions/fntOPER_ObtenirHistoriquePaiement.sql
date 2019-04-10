/****************************************************************************************************
Copyrights (c) 2018 Gestion Universitas inc.

Code du service     : fntOPER_ObtenirHistoriquePaiement
Nom du service		: 
But 				: Permet d'obtenir l'historique des chèques et des DDD pour une ou pour toutes les opérations
Description		: Cette fonction est appelée à chaque fois qu'il est nécesaire d'obtenir l'historique des paiements d'une opération
Facette			: OPER
Référence		: 

Paramètres d’entrée	: Paramètre			        Obligatoire	Description
					--------------------------	-----------	-----------------------------------------------------------------

Paramètres de sortie:	Table					Champ					        Description
	  				-------------------------	--------------------------- 	---------------------------------

Exemple d'appel : 
        SELECT * 
        FROM dbo.fntOPER_ObtenirHistoriquePaiement (NULL, NULL, 'ALL') -- Toutes les opérations
        WHERE IdOperationFinanciere = 29118430 
        SELECT * FROM dbo.fntOPER_ObtenirHistoriquePaiement (25628768, NULL, 'DDD') 
        SELECT * FROM dbo.fntOPER_ObtenirHistoriquePaiement (27827636, NULL, 'CHQ') 
        SELECT * FROM dbo.fntOPER_ObtenirHistoriquePaiement (28015600, NULL, 'ALL') 

Historique des modifications:
        Date        Programmeur			Description								Référence
        ----------  ------------------  ---------------------------  			------------
        2018-02-09  Pierre-Luc Simard   Création de la fonction	
		2018-03-22	Maxime Martel		Ajout pour retourner iCheckHistoryID
*********************************************************************************************************************/
CREATE FUNCTION [dbo].[fntOPER_ObtenirHistoriquePaiement]
(
    @IdOperationFinanciere INT = NULL,
    @dtDate_Etat DATETIME,
    @cType_Paiement CHAR(3) = 'ALL'
)
RETURNS TABLE AS
RETURN (
    SELECT 
        iID_Paiement = DD.Id, 
        Type_Paiement = 'DDD',
        DDD.IdOperationFinanciere, 
        DD.dtDate_Etat,
        vcEtat_PaiementFR =  CASE  
                    WHEN ISNULL(DDD.DateEffetRetourne, '9999-12-31') <= DD.dtDate_Etat THEN 'Refusée - DnD'
		            WHEN ISNULL(DDD.DateDecaissement, '9999-12-31')	<= DD.dtDate_Etat THEN 'Décaissée'
		            WHEN ISNULL(DDD.DateRejete, '9999-12-31') <= DD.dtDate_Etat THEN 'Rejetée - DnD'
            		-- S'il y a une date de rejet on fait comme si DateConfirmation est NULL
		            WHEN ISNULL(DDD.DateConfirmation, '9999-12-31') <= DD.dtDate_Etat AND ISNULL(DDD.DateRejete, '9999-12-31') > DD.dtDate_Etat THEN 'Confirmée'
		            WHEN ISNULL(DDD.DateConfirmation, '9999-12-31')	<= DD.dtDate_Etat AND ISNULL(DDD.DateRejete, '9999-12-31') <= DD.dtDate_Etat THEN 'Rejetée'
                    WHEN ISNULL(DDD.DateTransmission, '9999-12-31')	<= DD.dtDate_Etat THEN 'En traitement'
		            WHEN ISNULL(DDD.DateAnnule, '9999-12-31') <= DD.dtDate_Etat	THEN 'Annulée - DnD'
		            WHEN ISNULL(DDD.DateCreation, '9999-12-31') <= DD.dtDate_Etat THEN 'En attente'
		        ELSE 'ND'
		        END,
        vcEtat_PaiementEN =  CASE  
                    WHEN ISNULL(DDD.DateEffetRetourne, '9999-12-31') <= DD.dtDate_Etat THEN 'Refused - DnD'
		            WHEN ISNULL(DDD.DateDecaissement, '9999-12-31')	<= DD.dtDate_Etat THEN 'Withdrawn'
		            WHEN ISNULL(DDD.DateRejete, '9999-12-31') <= DD.dtDate_Etat THEN 'Rejected - DnD'
            		-- S'il y a une date de rejet on fait comme si DateConfirmation est NULL
		            WHEN ISNULL(DDD.DateConfirmation, '9999-12-31') <= DD.dtDate_Etat AND ISNULL(DDD.DateRejete, '9999-12-31') > DD.dtDate_Etat THEN 'Confirmed'
		            WHEN ISNULL(DDD.DateConfirmation, '9999-12-31')	<= DD.dtDate_Etat AND ISNULL(DDD.DateRejete, '9999-12-31') <= DD.dtDate_Etat THEN 'Rejected'
                    WHEN ISNULL(DDD.DateTransmission, '9999-12-31')	<= DD.dtDate_Etat THEN 'Processing'
		            WHEN ISNULL(DDD.DateAnnule, '9999-12-31') <= DD.dtDate_Etat	THEN 'Canceled - DnD'
		            WHEN ISNULL(DDD.DateCreation, '9999-12-31') <= DD.dtDate_Etat THEN 'Pending'
		        ELSE 'ND'
		        END,
        DDD.Montant, 
        DDD.InformationBancaireNumeroCompte, 
        NumeroPaiement = DD.Id,
        --DDD.DateDecaissement, 
        DestinatairePaiement = H.FirstName + ' ' + H.LastName,
		iCheckHistoryID = 0
    FROM (    
        SELECT DISTINCT 
            DDD.Id,
            DDD.dtDate_Etat
        FROM (
            SELECT 
                DDD.Id,
                dtDate_Etat = DDD.DateEffetRetourne
            FROM DecaissementDepotDirect DDD
            WHERE DDD.IdOperationFinanciere = ISNULL(@IdOperationFinanciere, DDD.IdOperationFinanciere)
            UNION 
            SELECT 
                DDD.Id,
                dtDate_Etat = DDD.DateDecaissement
            FROM DecaissementDepotDirect DDD
            WHERE DDD.IdOperationFinanciere = ISNULL(@IdOperationFinanciere, DDD.IdOperationFinanciere)
            UNION 
            SELECT 
                DDD.Id,
                dtDate_Etat = DDD.DateRejete
            FROM DecaissementDepotDirect DDD
            WHERE DDD.IdOperationFinanciere = ISNULL(@IdOperationFinanciere, DDD.IdOperationFinanciere)
            UNION 
            SELECT 
                DDD.Id,
                dtDate_Etat = DDD.DateConfirmation
            FROM DecaissementDepotDirect DDD
            WHERE DDD.IdOperationFinanciere = ISNULL(@IdOperationFinanciere, DDD.IdOperationFinanciere)
            UNION 
            SELECT 
                DDD.Id,
                dtDate_Etat = DDD.DateTransmission
            FROM DecaissementDepotDirect DDD
            WHERE DDD.IdOperationFinanciere = ISNULL(@IdOperationFinanciere, DDD.IdOperationFinanciere)
            UNION 
            SELECT 
                DDD.Id,
                dtDate_Etat = DDD.DateAnnule
            FROM DecaissementDepotDirect DDD
            WHERE DDD.IdOperationFinanciere = ISNULL(@IdOperationFinanciere, DDD.IdOperationFinanciere)
            UNION 
            SELECT 
                DDD.Id,
                dtDate_Etat = DDD.DateCreation
            FROM DecaissementDepotDirect DDD
            WHERE DDD.IdOperationFinanciere = ISNULL(@IdOperationFinanciere, DDD.IdOperationFinanciere)
        ) DDD
    WHERE ISNULL(DDD.dtDate_Etat, '9999-12-31') <= ISNULL(@dtDate_Etat, GETDATE())
        AND @cType_Paiement IN ('DDD', 'ALL')
    ) DD
    JOIN DecaissementDepotDirect DDD ON DDD.Id = DD.Id
    JOIN dbo.Mo_Human H ON H.HumanID = DDD.IdDestinataire

    UNION 

	SELECT DISTINCT
		iID_Paiement = C.iCheckID, 
        Type_Paiement = 'CHQ',
        IdOperationFinanciere = O.OperID,
		dtDate_Etat = CH.dtHistory,
		vcEtat_PaiementFR = CS.vcStatusDescription,
        vcEtat_PaiementEN = CS.vcStatusDescriptionEN,
        Montant = C.fAmount,
        InformationBancaireNumeroCompte = '',
        NumeroPaiement = CASE WHEN CS.iCheckStatusID IN (4, 5) THEN C.iCheckNumber ELSE NULL END,
        --DateDecaissement = C.dtEmission,
        DestinatairePaiement = C.vcFirstName + ' '	+ C.vcLastName,
		iCheckHistoryID = ISNULL(CH.iCheckHistoryID,0)
    FROM CHQ_Operation CO
	JOIN Un_OperLinkToCHQOperation L ON L.iOperationID = CO.iOperationID
	JOIN UN_Oper O ON O.OperID = L.OperID
	JOIN CHQ_OperationDetail OD ON OD.iOperationID = CO.iOperationID
	LEFT JOIN CHQ_CheckOperationDetail COD ON COD.iOperationDetailID = OD.iOperationDetailID
	LEFT JOIN CHQ_Check C ON C.iCheckID = COD.iCheckID 
	LEFT JOIN CHQ_CheckHistory CH ON CH.iCheckID = C.iCheckID
	LEFT JOIN CHQ_CheckStatus CS ON CS.iCheckStatusID = CH.iCheckStatusID
	WHERE @cType_Paiement IN ('CHQ', 'ALL')
        AND O.OperID = ISNULL(@IdOperationFinanciere, O.OperID)
        AND ISNULL(CH.dtHistory, '9999-12-31') <= ISNULL(@dtDate_Etat, GETDATE())
)