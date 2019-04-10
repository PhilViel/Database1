/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fnOPER_CalculerMontantOperationSurJVM
Nom du service		: Retourne le montant d'impacte de l'opération sur la JVM d'une convention
But 				: Retourne le montant d'impacte de l'opération sur la JVM d'une convention
Facette				: OPER

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						iID_Operation				Identifiant unique de l'opération.
						iID_Convention				Identifiant unique de la convention.
						

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						N/A							N/A								Montant d'impacte de l'opération 
																					sur la Juste Valeur Marchande de 
																					la convention fournie.
	
Exemple d'appel : SELECT dbo.fnOPER_CalculerMontantOperationSurJVM(1,1)

Historique des modifications:
		Date			Programmeur					Description						Référence
		------------	-------------------------	---------------------------  	------------
		2011-05-04		Corentin Menthonnex			Création du service
		
****************************************************************************************************/
CREATE FUNCTION [dbo].[fnOPER_CalculerMontantOperationSurJVM] ( @iID_Operation INT, @iID_Convention INT )
RETURNS MONEY
AS 
    BEGIN
		-- Déclaration des variables
        DECLARE @mMontant_Cotisations MONEY ;
        DECLARE @mMontant_Frais MONEY ;
        DECLARE @mMontant_Subventions MONEY ;
        DECLARE @mMontant_Conv_Oper MONEY ;
		        
        -- Récupération des cotisations et frais
        SELECT  @mMontant_Cotisations = SUM(ct.Cotisation) ,
                @mMontant_Frais = SUM(ct.Fee)
        FROM    dbo.Un_Cotisation ct
                INNER JOIN dbo.Un_Unit u ON u.UnitID = ct.UnitID
        WHERE   u.ConventionID = @iID_Convention
				AND ct.OperID = @iID_Operation ;
        
        -- Récupération des Subventions
        SELECT  @mMontant_Subventions = ( SUM(cesp.fCESG) + SUM(cesp.fACESG)
                                          + SUM(cesp.fCLB) + SUM(cesp.fPG) )
        FROM    dbo.Un_CESP cesp
        WHERE   cesp.ConventionID = @iID_Convention
				AND cesp.OperID = @iID_Operation ;
        
        -- Montant des opérations de la convention
        SELECT  @mMontant_Conv_Oper = SUM(co.ConventionOperAmount)
        FROM    dbo.Un_ConventionOper co
        WHERE   co.ConventionID = @iID_Convention
				AND co.OperID = @iID_Operation
                AND co.ConventionOperTypeID IN (SELECT val 
												FROM dbo.fn_Mo_StringTable(dbo.fnOPER_ObtenirTypesOperationConvCategorie('OPER_TYPE_CONV_POUR_CALCUL_JVM'))) ;
        
        RETURN ROUND((ISNULL(@mMontant_Cotisations, 0) + ISNULL(@mMontant_Frais, 0)
            + ISNULL(@mMontant_Subventions, 0) + ISNULL(@mMontant_Conv_Oper, 0)),2) ;
    END
