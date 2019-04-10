
/****************************************************************************************************
Code de service		:		fntOPER_ObtenirMontantConventionTINDiffere
Nom du service		:		Obtenir les intérets TIN dans le cas ou le capital du transfert est anti-daté (OperDate > EffectiveDate) 
But					:		Récupérer le montant d’intérêts TIN correspondant au transfert anti-daté sur un montant souscrit
Facette				:		P171U
Reférence			:		Relevé de dépôt
Parametres d'entrée :	Parametres					Description                                 Obligatoir
                        ----------                  ----------------                            --------------                       
                        iIdConvention	            Identifiant unique de la convention         Oui
						dtDateDebut	                Date de début
						dtDateFin	                Date de fin
						

Exemple d'appel:
                
                SELECT * FROM fntOPER_ObtenirMontantConventionTINDiffere (45212,NULL,NULL)

Parametres de sortie :  Table						Champs										Description
					    -----------------			---------------------------					--------------------------
                        Un_ConventionOper	        ConventionOperAmount	                    Montant de l’interet
						Un_ConventionOper	        ConventionOperDate	                        Date de l’opération sur la convention
						Un_Oper	                    mFrais	                                    Frais
						Un_Oper	                    iID_Oper	                                Identifiant unique de l’opération
						Un_Oper	                    OperDate	                                Date de l’opération
						Un_Oper	                    OperTypeID	                                Type d’opération
						Un_Cotisation               EffectDate                                  Date effective de l'opération

Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2011-12-09					Mbaye Diakhate 							Création de la fonction           
****************************************************************************************************/
CREATE FUNCTION [dbo].[fntOPER_ObtenirMontantConventionTINDiffere]
						( @iIdConvention INT,
						  @dtDateDebut DATETIME,
						  @dtDateFin DATETIME
						 )
RETURNS  @tMontantInterets 
	TABLE ( ConventionOperAmount MONEY,
			OperDate DATETIME,
			iID_Oper INT,
			OperTypeID CHAR(3),
			ConventionOperTypeID CHAR(3),
			ConventionID INT
			,EffectDate DATETIME)
BEGIN
	IF @dtDateDebut IS NULL SET @dtDateDebut = '1900/01/01'
	IF @dtDateFin IS NULL SET @dtDateFin = GETDATE()

		INSERT INTO @tMontantInterets
			 SELECT ConventionOperAmount =  CO.ConventionOperAmount,--Montant de l’interet
					OperDate = O.OperDate,--Date de l'operation
					iID_Oper = O.Operid,--l'id de l'operation
					OperTypeID = O.OperTypeID,--le type de l'operation
					ConventionOperTypeID = ConventionOperTypeID,
					conventionid = CO.ConventionID
					,EffectDate= COTI.EffectDate
			   FROM Un_ConventionOper CO
			   JOIN Un_Oper O ON O.OperID = CO.OperID
			   JOIN Un_Cotisation COTI ON COTI.OperID = O.OperID
			   JOIN tblOPER_OperationsCategorie OC on OperTypeID = OC.cID_Type_Oper 
							AND ConventionOperTypeID = OC.cID_Type_Oper_Convention
			   JOIN tblOPER_CategoriesOperation COP ON COP.iID_Categorie_Oper = OC.iID_Categorie_Oper
					AND COP.vcCode_Categorie = 'INT_PCEE_TIN_ITR' 
			  WHERE (O.OperDate >= @dtDateDebut AND O.OperDate <=  @dtDateFin)
			    AND ((COTI.EffectDate < @dtDateDebut) AND(COTI.EffectDate < o.OperDate)) 
				AND CO.ConventionID  = @iIdConvention 

	RETURN
END
