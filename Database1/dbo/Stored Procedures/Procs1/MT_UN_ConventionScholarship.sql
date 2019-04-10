/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	MT_UN_ConventionScholarship
Description         :	Retourne les bourses, les paiements sur celles-ci ainsi que le détail des paiements pour une
								convention.
Valeurs de retours  :	Dataset :
									ScholarshipID						INTEGER		ID unique de la bourse.
									ConventionID						INTEGER		ID unique de la convention.
									ScholarshipNo						SMALLINT		Numéro de la bourse.
									ScholarshipStatusID				CHAR(3)		Chaîne de 3 caractères qui donne l'état de la bourse ('RES'=En réserve, 'PAD'=Payée, 'ADM'=Admissible, 'WAI'=En attente, 'TPA'=À payer, 'DEA'=Décès, 'REN'=Renonciation, '25Y'=25 ans de régime, '24Y'=24 ans d'âge).
									ScholarshipAmount					MONEY			Montant de la bourse.
									ScholarshipPmtID					INTEGER		ID unique du paiement de bourse.
									OperID								INTEGER		ID unique de l’opération qui a effectué le paiement.
									OperTypeID							CHAR(3)		Code de 3 caractères du type d’opération.
									OperDate								DATETIME		Date d’opération.
									iOperationID						INTEGER		ID de l’opération dans le module des chèques
									HaveCheque							BIT			Indique s’il y a un chèque sur l’opération
									iCheckID								INTEGER 		ID unique du chèque
									iCheckNumber						INTEGER		Numéro du chèque
									dtCheckDate							DATETIME		Date du chèque
									CollegeID							INTEGER		ID unique de l’établissement d’enseignement.
									CollegeName							VARCHAR(75)	Établissement d’enseignement.
									ProgramID							INTEGER		ID unique du programme.
									ProgramDesc							VARCHAR(75)	Programme
									ProgramLenght						INTEGER		Durée du programme.
									ProgramYear							INTEGER		Année du programme.
									StudyStart							DATETIME		Date de début du programme.
									EligibilityConditionID			INTEGER		Condition d’admissibilité à la bourse.
									EligibilityQty						INTEGER		Quantité nécessaire à l’admissibilité.
									ScholarshipPmtDtlID				INTEGER		ID du détail du paiement. (Peut correspondre à un ConventionOperID, iCESPID ou un PlanOperID)
									ScholarshipPmtDtlOperTypeID 	CHAR(3)		Chaîne de 3 caractères indiquant le type de détail.
									ScholarshipPmtDtlAmount 		MONEY			Montant du détail.
Note                :			ADX0000732	IA	2005-07-06	Bruno Lapointe		Création
								ADX0000753	IA	2005-11-03	Bruno Lapointe		Changer les valeurs de retours +HaveCheque, 
																							+iCheckNumber, +fCheckAmount, +fCheckDate,
																							-ChequeID, -ChequeNo, -ChequeDate, 
																							-ChequeOrderID, -ChequeOrderDate, 
																							-ChequeOrderDesc, -ChequeName, -ChequeAmount,
																							-ChequeCancellationConnectID
								ADX0001746	BR	2005-11-23	Bruno Lapointe			Tri par numéro de bourse.
								ADX0000831	IA	2006-03-21	Bruno Lapointe			Adaptation des conventions pour PCEE 4.3
								ADX0001185	IA	2006-12-05	Bruno Lapointe			Optimisation
								ADX0002426  BR	2007-05-08	Bruno Lapointe			Fait une somme des 900
								ADX0002426	BR	2007-05-22	Bruno Lapointe			Création de la table Un_CESP.
												2010-01-18	Jean-François Gauthier	Ajout du champ EligibilityConditionID (table Un_ScholarshipPmt) en retour
												2013-01-03	Pierre-Luc Simard		Validation de tous les chèques pour une même opération, pas juste le dernier
												2014-09-24	Donald Huppé			Modification pour les DDD : on passe le operid dans le champ iOperationID.
												2018-01-10  Simon Tanguay			CRIT-208: Eliminer l'écran de versement des bourses dans Uniacces
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[MT_UN_ConventionScholarship]
    (
        @ConventionID INTEGER
    ) -- ID Unique de la convention.
AS
    BEGIN

		--UniAcces n'a plus besoin des valeurs de cette SP
        DECLARE @DummyTable TABLE
            (
                Bidon INT
            );

		SELECT *
        FROM   @DummyTable;

    END;